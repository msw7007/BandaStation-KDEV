import { Button, DmIcon, Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

type ItemCardProps = {
  name: string;
  icon?: string | null;
  iconState?: string | null;
  meta?: string;
  cost?: number;
  selected?: boolean;
  disabled?: boolean;
  tags?: string[];
  actionIcon?: string;
  onClick?: () => void;
  onAction?: () => void;
};

export function ItemCard(props: ItemCardProps) {
  const {
    actionIcon,
    cost,
    disabled,
    icon,
    iconState,
    meta,
    name,
    onAction,
    onClick,
    selected,
    tags,
  } = props;

  return (
    <button
      className={classes(['ItemCard', selected && 'selected'])}
      disabled={disabled}
      onClick={onClick}
    >
      <span className="ItemCard__icon">
        {!!icon && !!iconState ? (
          <DmIcon height="38px" width="38px" icon={icon} icon_state={iconState} />
        ) : (
          <Icon name="cube" />
        )}
      </span>
      <span className="ItemCard__body">
        <b>{name}</b>
        {!!meta && <small>{meta}</small>}
        {!!tags?.length && (
          <span className="ItemCard__tags">
            {tags.slice(0, 3).map((tag) => (
              <em key={tag}>{tag}</em>
            ))}
          </span>
        )}
      </span>
      {cost !== undefined && <span className="ItemCard__cost">{cost}</span>}
      {!!onAction && (
        <Button
          icon={actionIcon || 'plus'}
          onClick={(event) => {
            event.stopPropagation();
            onAction();
          }}
        />
      )}
    </button>
  );
}

