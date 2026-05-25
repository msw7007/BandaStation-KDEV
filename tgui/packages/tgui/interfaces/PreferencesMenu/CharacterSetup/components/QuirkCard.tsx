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

export function QuirkCard(props: QuirkCardProps) {
  const { disabled, onClick, quirk, reason, selected } = props;

  return (
    <div title={reason}>
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

