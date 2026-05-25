import { Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

type TraitCardProps = {
  name: string;
  description?: string | null;
  icon?: string;
  value?: number;
  selected?: boolean;
  disabled?: boolean;
  positive?: string | null;
  negative?: string | null;
  onClick?: () => void;
};

export function TraitCard(props: TraitCardProps) {
  const {
    description,
    disabled,
    icon,
    name,
    negative,
    onClick,
    positive,
    selected,
    value,
  } = props;

  return (
    <button
      className={classes([
        'TraitCard',
        selected && 'selected',
        value !== undefined && value > 0 && 'positive',
        value !== undefined && value < 0 && 'negative',
      ])}
      disabled={disabled}
      onClick={onClick}
    >
      <span className="TraitCard__icon">
        <Icon name={icon || 'diamond'} />
      </span>
      <span className="TraitCard__body">
        <b>{name}</b>
        {!!description && <small>{description}</small>}
        {!!positive && <em className="good">+ {positive}</em>}
        {!!negative && <em className="bad">- {negative}</em>}
      </span>
      {value !== undefined && <span className="TraitCard__value">{value}</span>}
    </button>
  );
}

