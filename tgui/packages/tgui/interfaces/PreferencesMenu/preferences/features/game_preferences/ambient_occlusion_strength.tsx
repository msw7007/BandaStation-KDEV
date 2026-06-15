import { type Feature, FeatureSliderInput } from '../base';

export const ambient_occlusion_strength: Feature<number> = {
  name: 'Ambient Occlusion Strength',
  category: 'Visuals',
  description:
    'Controls the depth shadow strength used when Ambient Occlusion is enabled. Range is 1-10; lower it for a flatter TG-like picture.',
  component: FeatureSliderInput,
};
