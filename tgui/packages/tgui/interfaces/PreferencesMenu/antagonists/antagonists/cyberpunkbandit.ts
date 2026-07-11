import { type Antagonist, Category } from '../base';

const CyberpunkBandit: Antagonist = {
  key: 'cyberpunkbandit',
  name: 'Bandit',
  description: [
    'Earn money, work with a gang, and spend credits through the black market drop system.',
  ],
  category: Category.Roundstart,
  priority: 1,
};

export default CyberpunkBandit;
