import { Button } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { JobPriority, type Job } from '../../types';

const priorityText: Record<number, string> = {
  [JobPriority.Low]: 'Низкий',
  [JobPriority.Medium]: 'Средний',
  [JobPriority.High]: 'Высокий',
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

export function RoleCard(props: RoleCardProps) {
  const { disabled, id, job, onPriority, onSelect, priority, selected } = props;

  return (
    <div className={classes(['RoleCard', selected && 'selected'])}>
      <button className="RoleCard__main" disabled={disabled} onClick={onSelect}>
        <b>{id}</b>
        <span>{job.department}</span>
        {!!priority && <em>{priorityText[priority]}</em>}
      </button>
      {!!onPriority && (
        <div className="RoleCard__priority">
          <Button
            selected={priority === JobPriority.Low}
            onClick={() => onPriority(JobPriority.Low)}
          >
            Н
          </Button>
          <Button
            selected={priority === JobPriority.Medium}
            onClick={() => onPriority(JobPriority.Medium)}
          >
            С
          </Button>
          <Button
            selected={priority === JobPriority.High}
            onClick={() => onPriority(JobPriority.High)}
          >
            В
          </Button>
          <Button icon="times" onClick={() => onPriority(null)} />
        </div>
      )}
    </div>
  );
}

