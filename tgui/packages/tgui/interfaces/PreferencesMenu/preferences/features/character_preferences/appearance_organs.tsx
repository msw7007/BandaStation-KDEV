import type { FeatureNumeric, FeatureToggle } from '../base';
import { CheckboxInput, FeatureSliderInput } from '../base';

export const breasts_size: FeatureNumeric = {
  name: 'Breast size',
  component: FeatureSliderInput,
};

export const penis_enabled: FeatureToggle = {
  name: 'Penis',
  component: CheckboxInput,
};

export const penis_size: FeatureNumeric = {
  name: 'Penis size',
  component: FeatureSliderInput,
};

export const testicles_size: FeatureNumeric = {
  name: 'Testicle size',
  component: FeatureSliderInput,
};

export const butt_size: FeatureNumeric = {
  name: 'Butt size',
  component: FeatureSliderInput,
};

export const belly_size: FeatureNumeric = {
  name: 'Belly size',
  component: FeatureSliderInput,
};

export const vagina_enabled: FeatureToggle = {
  name: 'Vagina',
  component: CheckboxInput,
};

export const vagina_size: FeatureNumeric = {
  name: 'Vagina size',
  component: FeatureSliderInput,
};

export const anus_size: FeatureNumeric = {
  name: 'Anus size',
  component: FeatureSliderInput,
};
