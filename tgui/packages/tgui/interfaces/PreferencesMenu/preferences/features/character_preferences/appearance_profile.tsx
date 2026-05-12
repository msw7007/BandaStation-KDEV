import type { FeatureChoiced } from '../base';
import { FeatureColorInput, FeatureTextInput } from '../base';
import { FeatureDropdownInput } from '../dropdowns';

export const body_height: FeatureChoiced = {
  name: 'Body height',
  component: FeatureDropdownInput,
};

export const sprite_size: FeatureChoiced = {
  name: 'Sprite size',
  component: FeatureDropdownInput,
};

export const sprite_width: FeatureChoiced = {
  name: 'Sprite width',
  component: FeatureDropdownInput,
};

export const lip_style: FeatureChoiced = {
  name: 'Lip style',
  component: FeatureDropdownInput,
};

export const lip_color = {
  name: 'Lip color',
  component: FeatureColorInput,
};

export const hidden_flavor_text = {
  name: 'Hidden-face description',
  description: 'Shown when the character face is obscured.',
  component: FeatureTextInput,
};

export const tts_voice_color = {
  name: 'TTS voice color',
  component: FeatureColorInput,
};

export const appearance_descriptor_1: FeatureChoiced = {
  name: 'Description 1',
  component: FeatureDropdownInput,
};

export const appearance_descriptor_2: FeatureChoiced = {
  name: 'Description 2',
  component: FeatureDropdownInput,
};

export const appearance_descriptor_3: FeatureChoiced = {
  name: 'Description 3',
  component: FeatureDropdownInput,
};

export const appearance_descriptor_4: FeatureChoiced = {
  name: 'Description 4',
  component: FeatureDropdownInput,
};
