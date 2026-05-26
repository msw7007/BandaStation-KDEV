import { classes } from 'tgui-core/react';
import type { MouseEvent } from 'react';

type PerkNodeProps = {
  name: string;
  description?: string;
  rank: number;
  maxRank: number;
  locked?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  onContextMenu?: (event: MouseEvent<HTMLButtonElement>) => void;
};

export function PerkNode(props: PerkNodeProps) {
  const {
    description,
    disabled,
    locked,
    maxRank,
    name,
    onClick,
    onContextMenu,
    rank,
  } = props;

  return (
    <button
      className={classes([
        'PerkNode',
        rank > 0 && 'taken',
        locked && 'locked',
      ])}
      disabled={disabled || locked}
      title={description}
      onClick={onClick}
      onContextMenu={onContextMenu}
    >
      <span>{name}</span>
      <b>
        {rank}/{maxRank}
      </b>
    </button>
  );
}
