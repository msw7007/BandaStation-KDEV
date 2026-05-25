import { Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

type SlotButtonProps = {
  label: string;
  icon?: string;
  state?: string;
  selected?: boolean;
  disabled?: boolean;
  warning?: string;
  onClick?: () => void;
};

export function SlotButton(props: SlotButtonProps) {
  const { disabled, icon, label, onClick, selected, state, warning } = props;

  return (
    <button
      className={classes([
        'SlotButton',
        selected && 'selected',
        warning && 'warning',
      ])}
      disabled={disabled}
      title={warning}
      onClick={onClick}
    >
      {!!icon && <Icon name={icon} />}
      <span>{label}</span>
      {!!state && <small>{state}</small>}
    </button>
  );
}

