import { CheckboxInput, type FeatureToggle } from '../base';

export const ambientocclusion: FeatureToggle = {
  name: 'Ambient Occlusion',
  category: 'Visuals',
  description:
    'Adds soft depth shadows around world objects. Use Ambient Occlusion Strength to tune the effect.',
  component: CheckboxInput,
};
