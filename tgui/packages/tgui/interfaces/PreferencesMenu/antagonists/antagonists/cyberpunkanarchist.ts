import { type Antagonist, Category } from '../base';

const CyberpunkAnarchist: Antagonist = {
  key: 'cyberpunkanarchist',
  name: 'Anarchist',
  description: [
    'Organize neural-interface recruits and damage corporate and government assets.',
  ],
  category: Category.Roundstart,
  priority: 3,
};

export default CyberpunkAnarchist;
