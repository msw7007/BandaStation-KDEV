import { type Feature, FeatureSliderInput } from '../base';

export const light_glare: Feature<number> = {
  name: 'Light Glare Strength',
  category: 'Visuals',
  description:
    'Adds a wide soft halo around emissive lights. Range is 1-10; high values are intentionally strong and cost more client-side GPU work.',
  component: FeatureSliderInput,
};
