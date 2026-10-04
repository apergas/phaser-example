package com.apergas.rpg.android.presentation.forest.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.presentation.forest.ForestLabels
import com.apergas.rpg.presentation.forest.HudState
import com.apergas.rpg.presentation.forest.QuestItemStatus

private enum class Panel { Quests, Build }

@Composable
fun HudOverlay(
    hud: HudState,
    onBuild: (BlueprintId) -> Unit,
    modifier: Modifier = Modifier,
) {
    var openPanel by remember { mutableStateOf<Panel?>(null) }
    val panelButtonColors = panelButtonColors()
    Box(modifier = modifier.fillMaxSize().padding(12.dp)) {
        Card(modifier = Modifier.align(Alignment.TopStart)) {
            Row(modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Text("${ForestLabels.WOOD} ${hud.wood}", color = MaterialTheme.colorScheme.primary)
                Text(ForestLabels.AXE, color = if (hud.hasAxe) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Column(modifier = Modifier.align(Alignment.TopEnd), horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(colors = panelButtonColors, onClick = { openPanel = if (openPanel == Panel.Quests) null else Panel.Quests }) {
                    Text("${ForestLabels.QUESTS} ${hud.questBadge}")
                }
                OutlinedButton(colors = panelButtonColors, enabled = !hud.isBuildLocked, onClick = { openPanel = if (openPanel == Panel.Build) null else Panel.Build }) {
                    Text(ForestLabels.BUILD)
                }
            }
            when (openPanel) {
                Panel.Quests -> Card(modifier = Modifier.widthIn(max = 320.dp)) {
                    Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        hud.quests.forEach { quest ->
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                Text(
                                    quest.title,
                                    // The title wraps, never the short progress text next to it.
                                    modifier = Modifier.weight(1f, fill = false),
                                    textDecoration = if (quest.status == QuestItemStatus.Done) TextDecoration.LineThrough else null,
                                    color = if (quest.status == QuestItemStatus.Pending) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface,
                                )
                                Text(quest.progressText, color = MaterialTheme.colorScheme.primary, softWrap = false)
                            }
                        }
                    }
                }
                Panel.Build -> Card(modifier = Modifier.widthIn(max = 320.dp)) {
                    Column(modifier = Modifier.padding(8.dp)) {
                        hud.buildItems.forEach { item ->
                            OutlinedButton(enabled = item.isEnabled, onClick = { openPanel = null; onBuild(item.blueprint) }) {
                                Text("${item.name} · ${item.costText}" + (item.missingText?.let { " · $it" } ?: ""))
                            }
                        }
                    }
                }
                null -> Unit
            }
        }
    }
}

/**
 * Touch bar shown while placing a building. It is the screen's bottom bar, so messages (snackbars) appear above it
 * instead of covering it.
 */
@Composable
fun PlacementBar(
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.navigationBars).padding(12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally),
    ) {
        Button(onClick = onConfirm) { Text(ForestLabels.Placement.CONFIRM) }
        OutlinedButton(colors = panelButtonColors(), onClick = onCancel) { Text(ForestLabels.Placement.CANCEL) }
    }
}

/** Like the web HUD, buttons sit on the dark panel colour so they stay readable over the forest. */
@Composable
private fun panelButtonColors() = ButtonDefaults.outlinedButtonColors(containerColor = MaterialTheme.colorScheme.surface)
