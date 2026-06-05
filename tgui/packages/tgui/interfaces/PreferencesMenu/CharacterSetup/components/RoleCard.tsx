import { classes } from 'tgui-core/react';

import { JobPriority, type Job } from '../../types';

const priorityText: Record<number, string> = {
  [JobPriority.Low]: 'Низкий',
  [JobPriority.Medium]: 'Средний',
  [JobPriority.High]: 'Высокий',
};

const roleNameText: Record<string, string> = {
  'City Worker': 'Житель',
  'Council Member': 'Член совета',
  'Government Officer': 'Правительство',
  'Police Officer': 'Офицер полиции',
  'Benn Intern': 'Интерн Бэнь',
  'Ryaznov Intern': 'Стажер Рязнов',
  'Starlight Intern': 'Подмастерье Старлайт',
  'Benn Agent': 'Оперативник Бэнь',
  'Ryaznov Agent': 'Агент Рязнов',
  'Starlight Agent': 'Боец Старлайт',
  'Benn Ripper Specialist': 'Специалист Бэнь',
  'Ryaznov Engineering Specialist': 'Инженер Рязнов',
  'Starlight Logistics Specialist': 'Мастер Старлайт',
  'Benn Representative': 'Глава представительства Бэнь',
  'Ryaznov Representative': 'Глава представительства Рязнов',
  'Starlight Representative': 'Глава представительства Старлайт',
  Mercenary: 'Наемник',
  Netrunner: 'Нетраннер',
  'Criminal Contractor': 'Серый подрядчик',
};

type RoleCardProps = {
  id: string;
  job: Job;
  selected?: boolean;
  priority?: JobPriority;
  disabled?: boolean;
  onSelect?: () => void;
  onPriority?: (priority: JobPriority | null) => void;
};

export function roleDisplayName(id: string) {
  return roleNameText[id] || id;
}

export function RoleCard(props: RoleCardProps) {
  const { disabled, id, onPriority, onSelect, priority, selected } = props;

  return (
    <div className={classes(['RoleCard', selected && 'selected'])}>
      <button className="RoleCard__main" disabled={disabled} onClick={onSelect}>
        <b>{roleDisplayName(id)}</b>
        {!!priority && <em>{priorityText[priority]}</em>}
      </button>
      {!!onPriority && (
        <div className="RoleCard__priority">
          <button
            className={classes([
              'RoleCard__priorityButton',
              priority === JobPriority.Low && 'selected',
            ])}
            onClick={() => onPriority(JobPriority.Low)}
          >
            Н
          </button>
          <button
            className={classes([
              'RoleCard__priorityButton',
              priority === JobPriority.Medium && 'selected',
            ])}
            onClick={() => onPriority(JobPriority.Medium)}
          >
            С
          </button>
          <button
            className={classes([
              'RoleCard__priorityButton',
              priority === JobPriority.High && 'selected',
            ])}
            onClick={() => onPriority(JobPriority.High)}
          >
            В
          </button>
          <button className="RoleCard__priorityButton" onClick={() => onPriority(null)}>
            Х
          </button>
        </div>
      )}
    </div>
  );
}
