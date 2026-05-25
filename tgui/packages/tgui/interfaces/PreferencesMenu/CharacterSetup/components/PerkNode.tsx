import { classes } from 'tgui-core/react';

type PerkNodeProps = {
  name: string;
  description?: string;
  rank: number;
  maxRank: number;
  locked?: boolean;
  disabled?: boolean;
  onClick?: () => void;
};

export function PerkNode(props: PerkNodeProps) {
  const { description, disabled, locked, maxRank, name, onClick, rank } = props;

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
    >
      <span>{name}</span>
      <b>
        {rank}/{maxRank}
      </b>
    </button>
  );
}

