import type { Quirk } from '../../types';
import { TraitCard } from './TraitCard';

type QuirkCardProps = {
  quirkKey: string;
  quirk: Quirk;
  selected?: boolean;
  disabled?: boolean;
  reason?: string;
  onClick?: () => void;
};

function quirkCostClass(value: number) {
  if (value < 0) {
    return 'cost-bad';
  }
  if (value > 0) {
    return 'cost-good';
  }
  return 'cost-mid';
}

export function QuirkCard(props: QuirkCardProps) {
  const { disabled, onClick, quirk, reason, selected } = props;

  return (
    <div className={`QuirkCard ${quirkCostClass(quirk.value)}`} title={reason}>
      <TraitCard
        disabled={disabled}
        icon={quirk.icon}
        name={quirk.name}
        description={quirk.description}
        selected={selected}
        value={quirk.value}
        onClick={onClick}
      />
    </div>
  );
}
