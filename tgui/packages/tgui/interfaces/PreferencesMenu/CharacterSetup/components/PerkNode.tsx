import type { CSSProperties, MouseEvent } from 'react';
import { Tooltip } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

type PerkNodeProps = {
  name: string;
  description?: string;
  rankDescriptions?: string[];
  rank: number;
  maxRank: number;
  skillKind?: string;
  locked?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  onContextMenu?: (event: MouseEvent<HTMLButtonElement>) => void;
};

const cyberCyan = '#18d8ff';
const cyberRed = '#ff334a';
const cyberText = '#d7e7ee';

function getRankDescription(
  description: string | undefined,
  rankDescriptions: string[] | undefined,
  level: number,
) {
  return rankDescriptions?.[level - 1] || description || 'Нет описания эффекта.';
}

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
    rankDescriptions,
    skillKind,
  } = props;
  const kindLabel =
    skillKind === 'professional'
      ? 'Профессиональный перк'
      : skillKind === 'physical'
        ? 'Физический перк'
        : 'Перк';

  const tooltip = (
    <div className="PerkNode__tooltip">
      <strong>{name}</strong>
      <em>{kindLabel}</em>
      <ol className="PerkNode__levels">
        {Array.from({ length: maxRank }, (_, index) => {
          const level = index + 1;
          const isTaken = level <= rank;
          const levelStyle: CSSProperties = {
            borderLeft: `3px solid ${isTaken ? cyberRed : cyberCyan}`,
          };
          const textStyle: CSSProperties = {
            color: isTaken ? cyberCyan : cyberText,
          };
          return (
            <li
              className={classes([
                isTaken ? 'taken' : 'pending',
              ])}
              key={level}
              style={levelStyle}
            >
              <b style={textStyle}>Уровень {level}</b>
              <span style={textStyle}>
                {getRankDescription(description, rankDescriptions, level)}
              </span>
            </li>
          );
        })}
      </ol>
      <b className="PerkNode__rank">
        {rank}/{maxRank}
      </b>
    </div>
  );

  return (
    <Tooltip content={tooltip} position="bottom">
      <button
        className={classes([
          'PerkNode',
          rank > 0 && 'taken',
          locked && 'locked',
          disabled && 'disabled',
        ])}
        aria-disabled={disabled || locked}
        onClick={onClick}
        onContextMenu={onContextMenu}
      >
        <span className="PerkNode__icon" />
        <b>
          {rank}/{maxRank}
        </b>
      </button>
    </Tooltip>
  );
}
