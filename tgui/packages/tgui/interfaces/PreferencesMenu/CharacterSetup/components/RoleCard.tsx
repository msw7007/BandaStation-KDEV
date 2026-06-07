import { Tooltip } from 'tgui-core/components';
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

const roleClassText: Record<string, string> = {
  agent: 'Корпоративный оперативник',
  council: 'Совет города',
  government: 'Правительство',
  intern: 'Корпоративный стажер',
  mercenary: 'Наемная работа',
  netrunner: 'Сетевая роль',
  officer: 'Силовая структура',
  specialist: 'Профильный специалист',
};

const corporationText: Record<string, string> = {
  benn: 'Бэнь',
  ryaznov: 'Рязнов',
  starlight: 'Старлайт',
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
  const { disabled, id, job, onPriority, onSelect, priority, selected } = props;
  const cyberRole = job.cyberpunk_role;
  const roleClass = cyberRole?.role_class
    ? roleClassText[cyberRole.role_class] || cyberRole.role_class
    : 'Городская роль';
  const roleGroup = cyberRole?.corporation
    ? corporationText[cyberRole.corporation] || cyberRole.corporation
    : cyberRole?.group || job.department;
  const tooltip = (
    <div className="RoleCard__tooltip">
      <strong>{roleDisplayName(id)}</strong>
      <span>{job.description || 'Описание роли пока не заполнено.'}</span>
      <dl>
        <dt>Направление</dt>
        <dd>{roleGroup}</dd>
        <dt>Ожидание</dt>
        <dd>{roleClass}</dd>
        {!!job.supervisors && (
          <>
            <dt>Кому подчиняется</dt>
            <dd>{job.supervisors}</dd>
          </>
        )}
      </dl>
      {!!cyberRole?.tasks?.length && (
        <ul>
          {cyberRole.tasks.map((task) => (
            <li key={task}>{task}</li>
          ))}
        </ul>
      )}
    </div>
  );

  return (
    <div className={classes(['RoleCard', selected && 'selected'])}>
      <Tooltip content={tooltip} position="top">
        <button
          aria-disabled={disabled}
          className="RoleCard__main"
          onClick={() => {
            if (!disabled) {
              onSelect?.();
            }
          }}
        >
          <b>{roleDisplayName(id)}</b>
          <span>{roleClass}</span>
          {!!priority && <em>{priorityText[priority]}</em>}
        </button>
      </Tooltip>
      {!!onPriority && (
        <div className="RoleCard__priority">
          <button
            className={classes([
              'RoleCard__priorityButton',
              priority === JobPriority.Low && 'selected',
            ])}
            onClick={() => onPriority(JobPriority.Low)}
          >
            Низкий
          </button>
          <button
            className={classes([
              'RoleCard__priorityButton',
              priority === JobPriority.Medium && 'selected',
            ])}
            onClick={() => onPriority(JobPriority.Medium)}
          >
            Средний
          </button>
          <button
            className={classes([
              'RoleCard__priorityButton',
              priority === JobPriority.High && 'selected',
            ])}
            onClick={() => onPriority(JobPriority.High)}
          >
            Высокий
          </button>
          <button
            className={classes([
              'RoleCard__priorityButton',
              !priority && 'selected',
            ])}
            onClick={() => onPriority(null)}
          >
            Отк.
          </button>
        </div>
      )}
    </div>
  );
}
