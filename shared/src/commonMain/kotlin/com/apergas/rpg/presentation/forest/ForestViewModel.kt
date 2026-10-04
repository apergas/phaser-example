package com.apergas.rpg.presentation.forest

import androidx.lifecycle.ViewModel
import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.ConstructionRejection
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.game.PlayerActivity
import com.apergas.rpg.domain.entities.game.PlayerStatus
import com.apergas.rpg.domain.entities.game.QuestProgress
import com.apergas.rpg.domain.entities.game.WorldSnapshot
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.usecases.game.GameUseCase
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlin.math.abs

/**
 * Presentation logic of the gameplay screen, shared by every platform: what a click means, the
 * placement mode, which message each event shows and which effect the view plays.
 *
 * Intents are handled synchronously (no `viewModelScope.launch`) because `Tick` must advance the
 * simulation in frame order on the drawing thread, and effects use `tryEmit` for the same reason.
 */
class ForestViewModel(private val gameUseCase: GameUseCase) : ViewModel() {
    private var lastPosition: Position
    private var facing = Facing.Down
    private var placement: Placement? = null
    private var hasGreeted = false

    private val _uiState: MutableStateFlow<ForestState>
    val uiState: StateFlow<ForestState>

    private val _uiEffect = MutableSharedFlow<ForestEffect>(extraBufferCapacity = 64)
    val uiEffect: SharedFlow<ForestEffect> = _uiEffect.asSharedFlow()

    init {
        gameUseCase.startGame()
        lastPosition = gameUseCase.playerStatus().position
        _uiState = MutableStateFlow(buildState())
        uiState = _uiState.asStateFlow()
    }

    fun worldSnapshot(): WorldSnapshot = gameUseCase.worldSnapshot()

    fun onIntent(intent: ForestIntent) {
        when (intent) {
            is ForestIntent.Tick -> tick(intent.deltaMs)
            is ForestIntent.MapClicked -> mapClicked(intent)
            is ForestIntent.PointerMoved -> pointerMoved(intent.position)
            is ForestIntent.BuildRequested -> buildRequested(intent.blueprint)
            ForestIntent.PlacementCancelled -> placement = null
        }
        _uiState.value = buildState()
    }

    private fun tick(deltaMs: Double) {
        if (!hasGreeted) {
            hasGreeted = true
            show(ForestLabels.Messages.WELCOME)
        }
        val fromX = gameUseCase.playerStatus().position.x
        gameUseCase.advance(deltaMs).forEach { react(it, fromX) }
    }

    private fun mapClicked(intent: ForestIntent.MapClicked) {
        val current = placement
        if (current != null) {
            if (intent.isSecondary) placement = null else place(current.blueprint, intent.position)
            return
        }
        if (intent.isSecondary) return
        if (intent.treeId != null) {
            if (gameUseCase.chopTree(intent.treeId) == ChopResult.NoAxe) show(ForestLabels.Messages.NEED_AXE)
        } else {
            gameUseCase.movePlayerTo(intent.position.x, intent.position.y)
        }
    }

    private fun pointerMoved(position: Position) {
        val current = placement ?: return
        placement = current.copy(position = position, isValid = gameUseCase.canPlaceBuilding(current.blueprint, position.x, position.y))
    }

    private fun buildRequested(blueprint: BlueprintId) {
        val option = gameUseCase.buildOptions().firstOrNull { it.blueprint == blueprint }
        if (option == null || !option.isAffordable) return show(ForestLabels.Messages.NOT_ENOUGH_WOOD)
        placement = Placement(blueprint, lastPosition, isValid = false)
        pointerMoved(lastPosition)
        show(ForestLabels.Messages.placing(ForestLabels.blueprint(blueprint)))
    }

    private fun place(blueprint: BlueprintId, position: Position) {
        when (val result = gameUseCase.constructBuilding(blueprint, position.x, position.y)) {
            is ConstructionResult.Started -> {
                placement = null
                show(ForestLabels.Messages.BUILDING_STARTED)
                _uiEffect.tryEmit(ForestEffect.BuildingPlaced(result.building))
            }
            is ConstructionResult.Rejected -> when (result.reason) {
                ConstructionRejection.Blocked -> show(ForestLabels.Messages.BLOCKED_SITE)
                ConstructionRejection.NotEnoughWood -> {
                    placement = null
                    show(ForestLabels.Messages.NOT_ENOUGH_WOOD)
                }
            }
        }
    }

    private fun react(event: GameEvent, fromX: Double) {
        when (event) {
            is GameEvent.ItemPickedUp -> {
                show(ForestLabels.Messages.PICKED_UP_AXE)
                _uiEffect.tryEmit(ForestEffect.ItemPickedUp(event.itemId))
            }
            GameEvent.PlayerBlocked -> show(ForestLabels.Messages.BLOCKED_PATH)
            is GameEvent.TreeHit -> _uiEffect.tryEmit(ForestEffect.TreeHit(event.treeId, fromX))
            is GameEvent.TreeFelled -> {
                show(ForestLabels.Messages.woodGained(event.wood))
                _uiEffect.tryEmit(ForestEffect.TreeFelled(event.treeId, fromX))
            }
            is GameEvent.BuildingHammered -> _uiEffect.tryEmit(ForestEffect.BuildingHammered(event.buildingId, event.progress))
            is GameEvent.BuildingCompleted -> {
                show(ForestLabels.Messages.buildingCompleted(ForestLabels.blueprint(event.blueprint)))
                _uiEffect.tryEmit(ForestEffect.BuildingCompleted(event.buildingId))
            }
            is GameEvent.QuestCompleted -> {
                val allDone = gameUseCase.quests().all { it.isCompleted }
                show(
                    if (allDone) ForestLabels.Messages.ALL_QUESTS_COMPLETED
                    else ForestLabels.Messages.questCompleted(ForestLabels.questTitle(event.questId)),
                )
            }
        }
    }

    private fun show(text: String) {
        _uiEffect.tryEmit(ForestEffect.ShowMessage(text))
    }

    private fun buildState(): ForestState {
        val status = gameUseCase.playerStatus()
        return ForestState(
            player = playerRenderState(status),
            hud = hudState(status, gameUseCase.quests()),
            placement = placement,
        )
    }

    /** Facing follows the movement; while working it faces the target instead. */
    private fun playerRenderState(status: PlayerStatus): PlayerRenderState {
        val dx = status.position.x - lastPosition.x
        val dy = status.position.y - lastPosition.y
        val isMoving = dx != 0.0 || dy != 0.0
        lastPosition = status.position

        val isWorking = status.activity == PlayerActivity.Chopping || status.activity == PlayerActivity.Constructing
        val target = status.target
        if (isWorking && target != null) facing = facingFor(target.x - status.position.x, target.y - status.position.y)
        else if (isMoving) facing = facingFor(dx, dy)

        val pose = when {
            isWorking -> PlayerPose.Work(
                tool = if (status.activity == PlayerActivity.Chopping) WorkTool.Axe else WorkTool.Hammer,
                swingProgress = status.swingProgress,
            )
            isMoving -> PlayerPose.Walk(withAxe = status.hasAxe)
            else -> PlayerPose.Idle(withAxe = status.hasAxe)
        }
        return PlayerRenderState(status.position, facing, pose)
    }

    private fun hudState(status: PlayerStatus, quests: List<QuestProgress>): HudState = HudState(
        wood = status.wood,
        hasAxe = status.hasAxe,
        questBadge = "${quests.count { it.isCompleted }}/${quests.size}",
        quests = quests.map { quest ->
            QuestItem(
                title = ForestLabels.questTitle(quest.id),
                progressText = when {
                    quest.isCompleted -> ForestLabels.QUEST_DONE
                    quest.target > 1 -> "${quest.progress}/${quest.target}"
                    else -> ""
                },
                status = when {
                    quest.isCompleted -> QuestItemStatus.Done
                    quest.isCurrent -> QuestItemStatus.Current
                    else -> QuestItemStatus.Pending
                },
            )
        },
        buildItems = gameUseCase.buildOptions().map { option ->
            BuildItem(
                blueprint = option.blueprint,
                name = ForestLabels.blueprint(option.blueprint),
                costText = ForestLabels.cost(option.woodCost),
                missingText = if (option.isAffordable) null else ForestLabels.missing(option.woodCost - status.wood),
                isEnabled = option.isAffordable,
            )
        },
        isBuildLocked = placement != null,
    )
}

private fun facingFor(dx: Double, dy: Double): Facing = when {
    abs(dx) > abs(dy) -> if (dx < 0) Facing.Left else Facing.Right
    else -> if (dy < 0) Facing.Up else Facing.Down
}
