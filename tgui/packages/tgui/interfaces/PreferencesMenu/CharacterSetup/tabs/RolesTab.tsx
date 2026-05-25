import { binaryInsertWith } from 'common/collections';
import { useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Button } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { type Antagonist, Category } from '../../antagonists/base';
import {
  JobPriority,
  type PreferencesMenuData,
  type ServerData,
} from '../../types';
import { useServerPrefs } from '../../useServerPrefs';
import { CyberButton } from '../components/CyberInput';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import { RoleCard } from '../components/RoleCard';
import { RoleGearPreview } from '../components/RoleGearPreview';

const requireAntag = require.context(
  '../../antagonists/antagonists',
  false,
  /.ts$/,
);

const antagsByCategory = new Map<Category, Antagonist[]>();

function binaryInsertAntag(collection: Antagonist[], value: Antagonist) {
  return binaryInsertWith(collection, value, (antag) => {
    return `${antag.priority}_${antag.name}`;
  });
}

for (const antagKey of requireAntag.keys()) {
  const antag = requireAntag<{
    default?: Antagonist;
  }>(antagKey).default;

  if (!antag) {
    continue;
  }

  antagsByCategory.set(
    antag.category,
    binaryInsertAntag(antagsByCategory.get(antag.category) || [], antag),
  );
}

function getJobsByDepartment(serverData: ServerData | undefined) {
  const jobs = serverData?.jobs.jobs || {};
  const departments: Record<string, string[]> = {};
  for (const [jobId, job] of Object.entries(jobs)) {
    departments[job.department] ||= [];
    departments[job.department].push(jobId);
  }
  return departments;
}

export function RolesTab() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();
  const jobs = serverData?.jobs.jobs || {};
  const departmentJobs = useMemo(() => getJobsByDepartment(serverData), [serverData]);
  const firstJob = Object.keys(jobs)[0];
  const [selectedRole, setSelectedRole] = useState(firstJob);
  const [roleType, setRoleType] = useState<'city' | 'adventure'>('city');
  const antags = [
    ...(antagsByCategory.get(Category.Roundstart) || []),
    ...(antagsByCategory.get(Category.Midround) || []),
    ...(antagsByCategory.get(Category.Latejoin) || []),
  ];

  function setDepartmentPriority(department: string, priority: JobPriority | null) {
    for (const job of departmentJobs[department] || []) {
      act('set_job_preference', {
        job,
        level: priority,
      });
    }
  }

  return (
    <div className="CharacterSetup__layout">
      <CyberPanel title="A. Настройки предпочтений ролей" scrollable>
        <CyberSectionHeader>Тип ролей</CyberSectionHeader>
        <div className="CharacterSetup__segmented">
          <button
            className={roleType === 'city' ? 'active' : ''}
            onClick={() => setRoleType('city')}
          >
            Городские роли
          </button>
          <button
            className={roleType === 'adventure' ? 'active' : ''}
            onClick={() => setRoleType('adventure')}
          >
            Приключенческие роли
          </button>
        </div>

        <CyberSectionHeader>Предпочтение по отделам</CyberSectionHeader>
        {Object.entries(departmentJobs).map(([department]) => (
          <div key={department} className="CharacterSetup__roleGroup">
            <b>{department}</b>
            <span>
              <Button onClick={() => setDepartmentPriority(department, JobPriority.Low)}>
                Низкое
              </Button>
              <Button onClick={() => setDepartmentPriority(department, JobPriority.Medium)}>
                Среднее
              </Button>
              <Button onClick={() => setDepartmentPriority(department, JobPriority.High)}>
                Высокое
              </Button>
            </span>
          </div>
        ))}

        <CyberSectionHeader>Настройки пулов ролей</CyberSectionHeader>
        <CyberButton disabled icon="layer-group">
          Пул ролей: TODO
        </CyberButton>
        <CyberButton disabled icon="arrow-down-short-wide">
          Минимальный приоритет: TODO
        </CyberButton>
        <CyberButton disabled icon="check">
          Учитывать предпочтения: TODO
        </CyberButton>
        <CyberButton disabled icon="shuffle">
          Заполнять пустые места вне предпочтений: TODO
        </CyberButton>
        <CyberButton danger icon="rotate-left" onClick={() => act('reset_role_preferences')}>
          Сбросить настройки ролей
        </CyberButton>
      </CyberPanel>

      <CyberPanel
        className="CharacterSetup__centerPanel"
        title="Превью выбранной роли"
        scrollable
      >
        <div className="CharacterSetup__roleBoard">
          {Object.entries(departmentJobs).map(([department, jobIds]) => (
            <div key={department} className="CharacterSetup__roleDepartment">
              <b>{department}</b>
              {jobIds.map((jobId) => (
                <RoleCard
                  key={jobId}
                  id={jobId}
                  job={jobs[jobId]}
                  selected={selectedRole === jobId}
                  priority={data.job_preferences[jobId]}
                  onSelect={() => setSelectedRole(jobId)}
                  onPriority={(priority) =>
                    act('set_job_preference', {
                      job: jobId,
                      level: priority,
                    })
                  }
                />
              ))}
            </div>
          ))}
        </div>
        <RoleGearPreview roleId={selectedRole} job={jobs[selectedRole]} />
      </CyberPanel>

      <CyberPanel title="B. Антагонисты" scrollable>
        <div className="CharacterSetup__antagGrid">
          {antags.map((antag) => {
            const selected = data.selected_antags.includes(antag.key);
            const banned = data.antag_bans?.includes(antag.key);
            const daysLeft = data.antag_days_left?.[antag.key] || 0;
            const disabled = !!banned || daysLeft > 0;
            return (
              <button
                key={antag.key}
                className={classes(['CharacterSetup__antag', selected && 'selected'])}
                disabled={disabled}
                title={
                  banned
                    ? `Бан на ${antag.name}`
                    : daysLeft > 0
                      ? `Доступно через ${daysLeft} дней`
                      : antag.description.join('\n')
                }
                onClick={() =>
                  act('set_antags', {
                    antags: [antag.key],
                    toggled: !selected,
                  })
                }
              >
                <span className={classes(['antagonists96x96', antag.key])} />
                <b>{antag.name}</b>
                <em>{disabled ? 'нельзя' : selected ? 'можно' : 'нельзя'}</em>
              </button>
            );
          })}
        </div>
        <div className="CharacterSetup__localNote">
          Эти настройки отражают только готовность игрока. Итоговый выбор
          зависит от раунда, правил сервера и storyteller/event logic.
        </div>
      </CyberPanel>
    </div>
  );
}

