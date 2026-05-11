/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

export const THEMES = ['light', 'dark'] as const;

export const COLORS = {
  DARK: {
    BG_BASE: '#02060a',
    BG_SECOND: '#071019',
    BUTTON: '#240811',
    TEXT: '#d7f5ff',
    BORDER: '#ff3046',
  },
  LIGHT: {
    BG_BASE: '#EEEEEE',
    BG_SECOND: '#FFFFFF',
    BUTTON: '#FFFFFF',
    TEXT: '#000000',
    BORDER: '#999999',
  },
} as const;

export const SETTINGS_TABS = [
  {
    id: 'general',
    name: 'General',
  },

  {
    id: 'textHighlight',
    name: 'Text Highlights',
  },
  {
    id: 'chatPage',
    name: 'Chat Tabs',
  },
  {
    id: 'statPanel',
    name: 'Stat Panel',
  },
] as const;

export const FONTS_DISABLED = 'Default';

export const FONTS = [
  FONTS_DISABLED,
  'Verdana',
  'Arial',
  'Arial Black',
  'Comic Sans MS',
  'Impact',
  'Lucida Sans Unicode',
  'Tahoma',
  'Trebuchet MS',
  'Courier New',
  'Lucida Console',
] as const;

export const WARN_AFTER_HIGHLIGHT_AMT = 10;
