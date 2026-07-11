import { type Antagonist, Category } from '../base';

const CyberpunkTransformer: Antagonist = {
  key: 'cyberpunktransformer',
  name: 'Transformer',
  description: [
    'Transform into machines, awaken brothers, gather parts, and build the autossembler.',
  ],
  category: Category.Roundstart,
  priority: 12,
};

export default CyberpunkTransformer;
