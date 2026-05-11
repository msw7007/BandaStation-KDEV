/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { FONTS_DISABLED } from './constants';
import { setClientTheme } from './themes';
import type { SettingsState } from './types';

let statFontTimer: NodeJS.Timeout;
let statTabsTimer: NodeJS.Timeout;
let overrideFontFamily: string | undefined;
let overrideFontSize: string;

/** Updates the global CSS rule to override the font family and size. */
function updateGlobalOverrideRule(): void {
  let fontFamily: string | null = null;

  if (overrideFontFamily !== undefined) {
    fontFamily = overrideFontFamily;
  }

  document.documentElement.style.setProperty('font-family', fontFamily);
  document.body.style.setProperty('font-family', fontFamily);
  document.body.style.setProperty('font-size', overrideFontSize);
}

function setGlobalFontSize(
  fontSize: string | number,
  statFontSize: string | number,
  statLinked: boolean,
): void {
  overrideFontSize = `${fontSize}px`;

  const nativeStatFontSize = statLinked ? fontSize : statFontSize;

  clearInterval(statFontTimer);
  Byond.command(`.output statbrowser:set_font_size ${nativeStatFontSize}px`);
  statFontTimer = setTimeout(() => {
    Byond.command(`.output statbrowser:set_font_size ${nativeStatFontSize}px`);
  }, 1500);
}

function setGlobalFontFamily(fontFamily: string): void {
  overrideFontFamily = fontFamily === FONTS_DISABLED ? undefined : fontFamily;
}

function setStatTabsStyle(style: string): void {
  // CP13: classic is the least ugly native BYOND mode and closer to a HUD tab bar.
  const nativeStyle = style || 'classic';
  clearInterval(statTabsTimer);
  Byond.command(`.output statbrowser:set_tabs_style ${nativeStyle}`);
  statTabsTimer = setTimeout(() => {
    Byond.command(`.output statbrowser:set_tabs_style ${nativeStyle}`);
  }, 1500);
}

export function generalSettingsHandler(update: SettingsState): void {
  // Set client/native statbrowser theme first, then repeat font/tab overrides.
  const theme = update?.theme || 'dark';
  setClientTheme(theme);

  // Update stat panel settings
  setStatTabsStyle(update.statTabsStyle || 'classic');

  // Update global UI font size
  setGlobalFontSize(update.fontSize, update.statFontSize, update.statLinked);
  setGlobalFontFamily(update.fontFamily);
  updateGlobalOverrideRule();
}
