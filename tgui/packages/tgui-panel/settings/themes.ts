/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { COLORS } from './constants';

let setClientThemeTimer: NodeJS.Timeout;

/**
 * Darkmode preference, originally by Kmc2000.
 *
 * This lets you switch client themes by using winset.
 *
 * If you change ANYTHING in interface/skin.dmf you need to change it here.
 * There's no way round it. We're essentially changing the skin by hand.
 * It's painful but it works, and is the way Lummox suggested.
 */
export function setClientTheme(name): void | Promise<void> {
  const themeColor = COLORS[name.toUpperCase()] ?? COLORS.DARK;

  // Native BYOND statbrowser only understands its own small theme protocol.
  // Feed it a dark theme, then hammer the skin controls with winset colors.
  // Unsupported control ids/properties are ignored by BYOND, so this list is
  // intentionally broad to cover tg upstream + downstream skin.dmf variants.
  clearInterval(setClientThemeTimer);
  applyNativeStatbrowserTheme(name, themeColor);
  setClientThemeTimer = setTimeout(() => {
    applyNativeStatbrowserTheme(name, themeColor);
  }, 1500);

  return Byond.winset({
    // Main windows
    'infobuttons.background-color': themeColor.BG_BASE,
    'infobuttons.text-color': themeColor.TEXT,
    'infowindow.background-color': themeColor.BG_BASE,
    'infowindow.text-color': themeColor.TEXT,
    'info_and_buttons.background-color': themeColor.BG_BASE,
    'info.background-color': themeColor.BG_BASE,
    'info.text-color': themeColor.TEXT,
    'browseroutput.background-color': themeColor.BG_BASE,
    'browseroutput.inner-background-color': themeColor.BG_BASE,
    'browseroutput.text-color': themeColor.TEXT,
    'outputwindow.background-color': themeColor.BG_BASE,
    'outputwindow.text-color': themeColor.TEXT,
    'mainwindow.background-color': themeColor.BG_BASE,
    'split.background-color': themeColor.BG_BASE,
    // Right/native stat panel variants.
    'statwindow.background-color': themeColor.BG_BASE,
    'statwindow.inner-background-color': themeColor.BG_BASE,
    'statwindow.text-color': themeColor.TEXT,
    'statwindow.border-color': themeColor.BORDER,
    'statpanel.background-color': themeColor.BG_BASE,
    'statpanel.inner-background-color': themeColor.BG_BASE,
    'statpanel.text-color': themeColor.TEXT,
    'statpanel.border-color': themeColor.BORDER,
    'statbrowser.background-color': themeColor.BG_BASE,
    'statbrowser.inner-background-color': themeColor.BG_BASE,
    'statbrowser.text-color': themeColor.TEXT,
    'statbrowser.border-color': themeColor.BORDER,
    'stat.background-color': themeColor.BG_BASE,
    'stat.inner-background-color': themeColor.BG_BASE,
    'stat.text-color': themeColor.TEXT,
    'stat.border-color': themeColor.BORDER,
    'stat_tabs.background-color': themeColor.BG_BASE,
    'stat_tabs.text-color': themeColor.TEXT,
    'stat_tabs.border-color': themeColor.BORDER,
    // Status and verb tabs/output controls.
    'output.background-color': themeColor.BG_BASE,
    'output.inner-background-color': themeColor.BG_BASE,
    'output.text-color': themeColor.TEXT,
    'output.border-color': themeColor.BORDER,
    // Buttons
    'changelog.background-color': themeColor.BUTTON,
    'changelog.text-color': themeColor.TEXT,
    'rules.background-color': themeColor.BUTTON,
    'rules.text-color': themeColor.TEXT,
    'wiki.background-color': themeColor.BUTTON,
    'wiki.text-color': themeColor.TEXT,
    'forum.background-color': themeColor.BUTTON,
    'forum.text-color': themeColor.TEXT,
    'github.background-color': themeColor.BUTTON,
    'github.text-color': themeColor.TEXT,
    'report-issue.background-color': themeColor.BUTTON,
    'report-issue.text-color': themeColor.TEXT,
    'fullscreen-toggle.background-color': themeColor.BUTTON,
    'fullscreen-toggle.text-color': themeColor.TEXT,
    // Say, OOC, me Buttons etc.
    'saybutton.background-color': themeColor.BG_BASE,
    'saybutton.text-color': themeColor.TEXT,
    'oocbutton.background-color': themeColor.BG_BASE,
    'oocbutton.text-color': themeColor.TEXT,
    'whisperbutton.background-color': themeColor.BG_BASE,
    'whisperbutton.text-color': themeColor.TEXT,
    'mebutton.background-color': themeColor.BG_BASE,
    'mebutton.text-color': themeColor.TEXT,
    'asset_cache_browser.background-color': themeColor.BG_BASE,
    'asset_cache_browser.inner-background-color': themeColor.BG_BASE,
    'asset_cache_browser.text-color': themeColor.TEXT,
    'tooltip.background-color': themeColor.BG_BASE,
    'tooltip.text-color': themeColor.TEXT,
    'input.background-color': themeColor.BG_SECOND,
    'input.text-color': themeColor.TEXT,
  });
}

function applyNativeStatbrowserTheme(name, themeColor): void {
  // `statbrowser` is a native BYOND output target, not the React chat panel.
  // It currently has limited protocol commands; real deep styling beyond these
  // requires replacing the native panel with a custom tgui window.
  const nativeTheme = name === 'light' ? 'light' : 'dark';
  Byond.command(`.output statbrowser:set_theme ${nativeTheme}`);
  Byond.command('.output statbrowser:set_tabs_style classic');
  Byond.command('.output statbrowser:set_font_size 13px');

  // These skin ids exist on some downstreams and are ignored on others.
  Byond.winset({
    'statbrowser.background-color': themeColor.BG_BASE,
    'statbrowser.inner-background-color': themeColor.BG_BASE,
    'statbrowser.text-color': themeColor.TEXT,
    'statbrowser.border-color': themeColor.BORDER,
    'statwindow.background-color': themeColor.BG_BASE,
    'statwindow.inner-background-color': themeColor.BG_BASE,
    'statwindow.text-color': themeColor.TEXT,
    'statwindow.border-color': themeColor.BORDER,
    'output.background-color': themeColor.BG_BASE,
    'output.inner-background-color': themeColor.BG_BASE,
    'output.text-color': themeColor.TEXT,
    'output.border-color': themeColor.BORDER,
  });
}
