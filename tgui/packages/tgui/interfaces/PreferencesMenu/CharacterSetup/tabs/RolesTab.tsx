import { binaryInsertWith } from 'common/collections';
import { useEffect, useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { classes } from 'tgui-core/react';

import { type Antagonist, Category } from '../../antagonists/base';
import {
  JobPriority,
  type Job,
  type PreferencesMenuData,
  type ServerData,
} from '../../types';
import { useServerPrefs } from '../../useServerPrefs';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import { RoleCard } from '../components/RoleCard';
import { RoleGearPreview } from '../components/RoleGearPreview';

const requireAntag = require.context(
  '../../antagonists/antagonists',
  false,
  /.ts$/,
);

const antagsByCategory = new Map<Category, Antagonist[]>();

const roleFilters = [
  ['all', 'Все'],
  ['city', 'Городские'],
  ['corporate', 'Корпорация'],
  ['deletion', 'Удаление'],
] as const;

type RoleFilter = (typeof roleFilters)[number][0];

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

function canShowJob(job: Job, data: PreferencesMenuData) {
  return job.cyberpunk_role?.role_class !== 'government' || !!data.is_admin;
}

function getJobsForFilter(
  serverData: ServerData | undefined,
  filter: RoleFilter,
  data: PreferencesMenuData,
) {
  const allJobs = serverData?.jobs.jobs || {};
  return Object.fromEntries(
    Object.entries(allJobs).filter(([, job]) => {
      const standalone = !!job.cyberpunk_role?.standalone;
      if (job.cyberpunk_role?.role_class === 'netrunner') {
        return false;
      }
      if (!canShowJob(job, data)) {
        return false;
      }
      if (filter === 'deletion') {
        return !standalone;
      }
      if (!standalone) {
        return false;
      }
      const group = job.cyberpunk_role?.group || 'city';
      if (filter === 'all') {
        return true;
      }
      if (filter === 'city') {
        return group === 'city' || group === 'mercenary';
      }
      return group === filter;
    }),
  );
}

function firstJobId(jobs: Record<string, Job>) {
  return Object.keys(jobs)[0];
}

export function RolesTab() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();
  const [roleFilter, setRoleFilter] = useState<RoleFilter>('all');
  const jobs = useMemo(
    () => getJobsForFilter(serverData, roleFilter, data),
    [serverData, roleFilter, data],
  );
  const fallbackRole = firstJobId(jobs);
  const [selectedRole, setSelectedRole] = useState(fallbackRole);
  const [selectedAntags, setSelectedAntags] = useState(
    () => new Set(data.selected_antags),
  );
  const visibleRole = selectedRole && jobs[selectedRole] ? selectedRole : fallbackRole;
  const antags = [
    ...(antagsByCategory.get(Category.Roundstart) || []),
    ...(antagsByCategory.get(Category.Midround) || []),
    ...(antagsByCategory.get(Category.Latejoin) || []),
  ];

  function selectRoleFilter(nextFilter: RoleFilter) {
    setRoleFilter(nextFilter);
    const nextRole = firstJobId(getJobsForFilter(serverData, nextFilter, data));
    if (nextRole) {
      setSelectedRole(nextRole);
    }
  }

  useEffect(() => {
    setSelectedAntags(new Set(data.selected_antags));
  }, [data.selected_antags]);

  useEffect(() => {
    if (!visibleRole) {
      return;
    }
    act('set_role_preview_job', {
      job: visibleRole,
    });
  }, [act, visibleRole]);

  useEffect(() => {
    return () => {
      act('set_role_preview_job', {
        clear: true,
      });
    };
  }, [act]);

  return (
    <div className="CharacterSetup__layout">
      <CyberPanel title="A. Предпочтения ролей" scrollable>
        <CyberSectionHeader>Фильтр ролей</CyberSectionHeader>
        <div className="CharacterSetup__segmented">
          {roleFilters.map(([id, label]) => (
            <button
              key={id}
              className={roleFilter === id ? 'active' : ''}
              onClick={() => selectRoleFilter(id)}
            >
              {label}
            </button>
          ))}
        </div>

        <CyberSectionHeader>Профессии</CyberSectionHeader>
        <div className="CharacterSetup__roleList">
          {Object.entries(jobs).map(([jobId, job]) => (
            <RoleCard
              key={jobId}
              id={jobId}
              job={job}
              selected={visibleRole === jobId}
              priority={data.job_preferences[jobId]}
              onSelect={() => {
                setSelectedRole(jobId);
                act('set_role_preview_job', {
                  job: jobId,
                });
              }}
              onPriority={(priority) =>
                act('set_job_preference', {
                  job: jobId,
                  level: priority,
                })
              }
            />
          ))}
        </div>
      </CyberPanel>

      <CyberPanel
        className="CharacterSetup__centerPanel"
        title="Превью выбранной роли"
      >
        <RoleGearPreview
          previewId={data.character_preview_view}
          roleId={visibleRole}
          job={jobs[visibleRole]}
        />
      </CyberPanel>

      <CyberPanel title="B. Антагонисты" scrollable>
        <div className="CharacterSetup__antagGrid">
          {antags.map((antag) => {
            const selected = selectedAntags.has(antag.key);
            const banned = data.antag_bans?.includes(antag.key);
            const daysLeft = data.antag_days_left?.[antag.key] || 0;
            const disabled = !!banned || daysLeft > 0;
            return (
              <button
                key={antag.key}
                className={classes([
                  'CharacterSetup__antag',
                  selected && 'selected',
                  disabled && 'disabled',
                  !selected && !disabled && 'available',
                ])}
                aria-disabled={disabled}
                title={
                  banned
                    ? `Бан на ${antag.name}`
                    : daysLeft > 0
                      ? `Доступно через ${daysLeft} дней`
                      : antag.description.join('\n')
                }
                onClick={() => {
                  if (disabled) {
                    return;
                  }
                  const nextAntags = new Set(selectedAntags);
                  if (selected) {
                    nextAntags.delete(antag.key);
                  } else {
                    nextAntags.add(antag.key);
                  }
                  setSelectedAntags(nextAntags);
                  act('set_antags', {
                    antags: [antag.key],
                    toggled: !selected,
                  });
                }}
              >
                <span className={classes(['antagonists96x96', antag.key])} />
                <b>{antag.name}</b>
              </button>
            );
          })}
        </div>
        <div className="CharacterSetup__localNote">
          Эти настройки отражают готовность игрока. Итоговый выбор зависит от раунда,
          правил сервера и storyteller/event logic.
        </div>
      </CyberPanel>
    </div>
  );
}
