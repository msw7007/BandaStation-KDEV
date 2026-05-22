import {
  type Feature,
  type FeatureChoiced,
  FeatureColorInput,
  FeatureNumberInput,
  FeatureTextInput,
} from '../base';
import { FeatureDropdownInput } from '../dropdowns';

export const sprite_size: Feature<number> = {
  name: 'Sprite size',
  component: FeatureNumberInput,
};

export const sprite_height: Feature<number> = {
  name: 'Sprite height',
  component: FeatureNumberInput,
};

export const sprite_width: Feature<number> = {
  name: 'Sprite width',
  component: FeatureNumberInput,
};

export const body_shape: FeatureChoiced = {
  name: 'Body shape',
  component: FeatureDropdownInput,
};

export const appearance_descriptor_1: FeatureChoiced = {
  name: 'Descriptor 1',
  component: FeatureDropdownInput,
};

export const appearance_descriptor_2: FeatureChoiced = {
  name: 'Descriptor 2',
  component: FeatureDropdownInput,
};

export const appearance_descriptor_3: FeatureChoiced = {
  name: 'Descriptor 3',
  component: FeatureDropdownInput,
};

export const appearance_descriptor_4: FeatureChoiced = {
  name: 'Descriptor 4',
  component: FeatureDropdownInput,
};

export const flavor_text: Feature<string> = {
  name: 'Flavor',
  component: FeatureTextInput,
};

export const incognito_adjective: FeatureChoiced = {
  name: 'Incognito adjective',
  component: FeatureDropdownInput,
};

export const incognito_noun: FeatureChoiced = {
  name: 'Incognito noun',
  component: FeatureDropdownInput,
};

export const voice_adjective: FeatureChoiced = {
  name: 'Voice adjective',
  component: FeatureDropdownInput,
};

export const voice_noun: FeatureChoiced = {
  name: 'Voice noun',
  component: FeatureDropdownInput,
};

export const voice_color: Feature<string> = {
  name: 'Voice color',
  component: FeatureColorInput,
};
