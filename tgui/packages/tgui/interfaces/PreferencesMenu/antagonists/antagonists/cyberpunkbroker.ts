import { type Antagonist, Category } from '../base';

const CyberpunkBroker: Antagonist = {
  key: 'cyberpunkbroker',
  name: 'Broker',
  description: [
    'Deploy breach anchors, escalate mech abilities, and overwhelm resistance with nanites.',
  ],
  category: Category.Roundstart,
  priority: 13,
};

export default CyberpunkBroker;
