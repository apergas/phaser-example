package com.apergas.rpg.android.presentation.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/** Same palette as the web HUD (hud.css). */
private val HudColors = darkColorScheme(
    primary = Color(0xFFE8C05A),
    onPrimary = Color(0xFF1C1610),
    surface = Color(0xD11C1610),
    onSurface = Color(0xFFF3E7CF),
    onSurfaceVariant = Color(0xFFB9A888),
    outline = Color(0xFF8A6A3F),
)

@Composable
fun RpgTheme(content: @Composable () -> Unit) = MaterialTheme(colorScheme = HudColors, content = content)
