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
  neutral?: string | null;
  onClick?: () => void;
};

export function TraitCard(props: TraitCardProps) {
  const {
    description,
    disabled,
    icon,
    name,
    negative,
    neutral,
    onClick,
    positive,
    selected,
    value,
  } = props;

  return (
    <div
      className={classes([
        'TraitCard',
        selected && 'selected',
        disabled && 'disabled',
        value !== undefined && value > 0 && 'positive',
        value !== undefined && value < 0 && 'negative',
      ])}
      role="button"
      tabIndex={disabled ? -1 : 0}
      onClick={disabled ? undefined : onClick}
      onKeyDown={(event) => {
        if (disabled || !onClick) {
          return;
        }
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          onClick();
        }
      }}
    >
      <span className="TraitCard__icon">
        <Icon name={icon || 'diamond'} />
      </span>
      <span className="TraitCard__body">
        <b>{name}</b>
        {!!description && <small>{description}</small>}
        {!!positive && <em className="good">+ {positive}</em>}
        {!!negative && <em className="bad">- {negative}</em>}
        {!!neutral && <em className="neutral">± {neutral}</em>}
      </span>
      {value !== undefined && <span className="TraitCard__value">{value}</span>}
    </div>
  );
}
