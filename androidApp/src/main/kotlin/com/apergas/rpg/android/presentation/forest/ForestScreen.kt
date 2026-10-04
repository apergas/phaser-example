package com.apergas.rpg.android.presentation.forest

import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.toSize
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.apergas.rpg.android.presentation.forest.components.HudOverlay
import com.apergas.rpg.android.presentation.forest.components.PlacementBar
import com.apergas.rpg.android.presentation.forest.world.CAMERA_ZOOM
import com.apergas.rpg.android.presentation.forest.world.LpcAssets
import com.apergas.rpg.android.presentation.forest.world.WorldCanvas
import com.apergas.rpg.android.presentation.forest.world.WorldSceneState
import com.apergas.rpg.android.presentation.forest.world.cameraOrigin
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.ForestEffect
import com.apergas.rpg.presentation.forest.ForestIntent
import com.apergas.rpg.presentation.forest.ForestLabels
import com.apergas.rpg.presentation.forest.ForestViewModel
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

@Composable
fun ForestScreen(viewModel: ForestViewModel, modifier: Modifier = Modifier) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val assets = remember { LpcAssets(context) }
    val scene = remember { WorldSceneState(viewModel.worldSnapshot()) }
    val snackbarHostState = remember { SnackbarHostState() }
    var frameNanos by remember { mutableLongStateOf(0L) }

    val messageScope = rememberCoroutineScope()

    LaunchedEffect(viewModel) {
        viewModel.uiEffect.collect { effect ->
            if (effect is ForestEffect.ShowMessage) {
                // showSnackbar suspends until the message goes away: it runs apart so the next effects are not
                // held back, and a new message replaces the current one, like the web HUD.
                messageScope.launch {
                    snackbarHostState.currentSnackbarData?.dismiss()
                    snackbarHostState.showSnackbar(effect.text)
                }
            } else {
                scene.play(effect, frameNanos)
            }
        }
    }
    LaunchedEffect(viewModel) {
        var last = androidx.compose.runtime.withFrameNanos { it }
        while (isActive) {
            androidx.compose.runtime.withFrameNanos { now ->
                viewModel.onIntent(ForestIntent.Tick((now - last) / 1_000_000.0))
                last = now
                frameNanos = now
                scene.prune(now)
            }
        }
    }

    ForestScaffold(
        snackbarHostState = snackbarHostState,
        bottomBar = {
            if (state.placement != null) {
                PlacementBar(
                    onConfirm = { state.placement?.let { viewModel.onIntent(ForestIntent.MapClicked(it.position, treeId = null)) } },
                    onCancel = { viewModel.onIntent(ForestIntent.PlacementCancelled) },
                )
            }
        },
        modifier = modifier,
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize()) {
            val description = ForestLabels.Accessibility.GAME_WORLD
            WorldCanvas(
                scene = scene,
                player = state.player,
                placement = state.placement,
                assets = assets,
                frameNanos = frameNanos,
                modifier = Modifier
                    .fillMaxSize()
                    .semantics { contentDescription = description }
                    .pointerInput(Unit) {
                        detectTapGestures { tap ->
                            val origin = cameraOrigin(state.player.position, scene, this.size.toSize())
                            val world = Position((origin.x + tap.x / CAMERA_ZOOM).toDouble(), (origin.y + tap.y / CAMERA_ZOOM).toDouble())
                            if (state.placement != null) viewModel.onIntent(ForestIntent.PointerMoved(world))
                            else viewModel.onIntent(ForestIntent.MapClicked(world, scene.treeAt(world, assets)))
                        }
                    },
            )
            HudOverlay(
                hud = state.hud,
                onBuild = { viewModel.onIntent(ForestIntent.BuildRequested(it)) },
                modifier = Modifier.padding(padding),
            )
        }
    }
}

@Composable
private fun ForestScaffold(
    snackbarHostState: SnackbarHostState,
    bottomBar: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable (PaddingValues) -> Unit,
) {
    Scaffold(modifier = modifier, bottomBar = bottomBar, snackbarHost = { SnackbarHost(snackbarHostState) }, content = content)
}
