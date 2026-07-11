import { type Antagonist, Category } from '../base';

const CyberpunkCorporateSpy: Antagonist = {
  key: 'cyberpunkcorporatespy',
  name: 'Corporate Spy',
  description: [
    'Act as a hidden agent inside a rival corporation and upload daily task results.',
  ],
  category: Category.Roundstart,
  priority: 2,
};

export default CyberpunkCorporateSpy;
