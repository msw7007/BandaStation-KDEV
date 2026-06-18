import { binaryInsertWith } from 'common/collections';
import { useEffect, useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Button } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { type Antagonist, Category } from '../../antagonists/base';
import {
  JobPriority,
  type Job,
  type PreferencesMenuData,
  type ServerData,
} from '../../types';
import { useServerPrefs } from '../../useServerPrefs';
import { CyberInput } from '../components/CyberInput';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import { RoleCard } from '../components/RoleCard';
import { RoleGearPreview } from '../components/RoleGearPreview';
import { SkillTree } from '../components/SkillTree';
import { attributeOrder, numberValue } from '../helpers';

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

type RoleSetupPanelProps = {
  roleId?: string;
  job?: Job;
};

function RoleSetupPanel(props: RoleSetupPanelProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();
  const { job, roleId } = props;
  const setup = roleId ? data.character_role_setups?.[roleId] : undefined;
  const [titleDraft, setTitleDraft] = useState('');

  useEffect(() => {
    setTitleDraft(setup?.custom_title || '');
  }, [roleId, setup?.custom_title]);

  if (!roleId || !job || !setup) {
    return (
      <div className="CharacterSetup__localNote">
        Выберите роль слева, чтобы открыть настройку ее бонусов.
      </div>
    );
  }

  const hasAttributePool = !!setup.attribute_points_max;
  const hasProfessionalPool = !!setup.professional_skill_points_max;
  const hasWeaponPool = !!setup.weapon_skill_points_max;
  const hasAnyPool = hasAttributePool || hasProfessionalPool || hasWeaponPool;
  const attributeDefs = serverData?.character_setup?.attributes || {};
  const rolePhysicalSkills = (serverData?.character_setup?.physical_skills || []).filter(
    (skill) => !!setup.attributes[skill.attribute_id]?.bonus,
  );

  const adjustPerk = (skillId: string, perkIndex: number, delta: number) =>
    act('adjust_role_perk', {
      job: roleId,
      skill: skillId,
      perk_index: perkIndex,
      delta,
    });

  const adjustSkillLevel = (skillId: string, delta: number) =>
    act('adjust_role_skill_level', {
      job: roleId,
      skill: skillId,
      delta,
    });

  const saveTitle = () =>
    act('set_role_custom_title', {
      job: roleId,
      title: titleDraft,
    });

  return (
    <div className="CharacterSetup__roleSetup">
      <div className="CharacterSetup__roleSetupHeader">
        <div>
          <b>{roleId}</b>
          <span>
            Бонус роли сохраняется отдельно и накладывается поверх биометрики
            только при появлении за эту роль.
          </span>
        </div>
        <div className="CharacterSetup__roleSetupPools">
          {!!setup.attribute_points_max && (
            <span>Физ. перки: {setup.attribute_points}/{setup.attribute_points_max}</span>
          )}
          {!!setup.professional_skill_points_max && (
            <span>
              Профа: {setup.professional_skill_points}/
              {setup.professional_skill_points_max}
            </span>
          )}
          {!!setup.weapon_skill_points_max && (
            <span>
              Оружие: {setup.weapon_skill_points}/{setup.weapon_skill_points_max}
            </span>
          )}
        </div>
      </div>

      {setup.can_rename ? (
        <div className="CharacterSetup__roleTitle">
          <CyberInput
            icon="id-card"
            label="Название"
            placeholder={roleId}
            value={titleDraft}
            onChange={setTitleDraft}
          />
          <div className="CharacterSetup__roleTitleActions">
            <Button icon="check" onClick={saveTitle}>
              Сохранить
            </Button>
            <Button
              icon="rotate-left"
              disabled={!setup.custom_title && !titleDraft}
              onClick={() => {
                setTitleDraft('');
                act('set_role_custom_title', {
                  job: roleId,
                  title: '',
                });
              }}
            >
              Сбросить
            </Button>
          </div>
        </div>
      ) : null}

      {!hasAnyPool && (
        <div className="CharacterSetup__localNote">
          У этой роли пока нет распределяемых бонусных очков.
        </div>
      )}

      {hasAttributePool && (
        <>
          <CyberSectionHeader>Характеристики</CyberSectionHeader>
          <div className="CharacterSetup__roleAttributeGrid">
            {attributeOrder
              .filter((attributeId) => !!setup.attributes[attributeId]?.bonus)
              .map((attributeId) => {
              const attribute = attributeDefs[attributeId];
              const runtime = setup.attributes[attributeId];
              return (
                <div
                  key={attributeId}
                  className="CharacterSetup__roleAttributeBonus"
                >
                  <div>
                    <b>{attribute?.name || attributeId}</b>
                    <span>
                      База {runtime?.base_value ?? 5}, итог {runtime?.value ?? 5}
                    </span>
                  </div>
                  <strong>+{runtime?.bonus || 0}</strong>
                </div>
              );
            })}
          </div>
          {!!rolePhysicalSkills.length && (
            <>
              <CyberSectionHeader>Физические навыки роли</CyberSectionHeader>
              <SkillTree
                className="SkillTree--physical"
                compact
                runtimeSkills={setup.skills}
                skills={rolePhysicalSkills}
                onAdjustPerk={adjustPerk}
              />
            </>
          )}
        </>
      )}

      {hasProfessionalPool && (
        <>
          <CyberSectionHeader>Профессиональные навыки</CyberSectionHeader>
          <SkillTree
            className="SkillTree--professional"
            compact
            runtimeSkills={setup.skills}
            skills={serverData?.character_setup?.professional_skills || []}
            onAdjustPerk={adjustPerk}
          />
        </>
      )}

      {hasWeaponPool && (
        <>
          <CyberSectionHeader>Боевые / оружейные навыки</CyberSectionHeader>
          <SkillTree
            compact
            runtimeSkills={setup.skills}
            skills={serverData?.character_setup?.weapon_skills || []}
            onAdjustSkillLevel={adjustSkillLevel}
          />
        </>
      )}
    </div>
  );
}

export function RolesTab() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();
  const [roleFilter, setRoleFilter] = useState<RoleFilter>('all');
  const [setupMode, setSetupMode] = useState(false);
  const jobs = useMemo(
    () => getJobsForFilter(serverData, roleFilter, data),
    [serverData, roleFilter, data.is_admin],
  );
  const fallbackRole = firstJobId(jobs);
  const [selectedRole, setSelectedRole] = useState<string | undefined>();
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
    setSelectedRole(undefined);
    setSetupMode(false);
  }

  function previewRole(jobId: string) {
    setSelectedRole(jobId);
    act('set_role_preview_job', {
      job: jobId,
    });
  }

  useEffect(() => {
    setSelectedAntags(new Set(data.selected_antags));
  }, [data.selected_antags]);

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
        <div className="CharacterSetup__textSwitch CharacterSetup__textSwitch--roleFilter">
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
              selected={selectedRole === jobId}
              priority={data.job_preferences[jobId]}
              setupActive={setupMode && visibleRole === jobId}
              onSelect={() => {
                previewRole(jobId);
                setSetupMode(false);
              }}
              onSetup={() => {
                previewRole(jobId);
                setSetupMode(setupMode && visibleRole === jobId ? false : true);
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
        {!setupMode && (
          <RoleGearPreview
            previewImage={data.character_preview_icon}
            previewId={selectedRole ? data.character_preview_view : undefined}
            previewScale={numberValue(data, 'sprite_size', 1)}
            previewScaleX={numberValue(data, 'sprite_width', 1)}
            previewScaleY={numberValue(data, 'sprite_height', 1)}
            roleId={visibleRole}
            job={jobs[visibleRole]}
          />
        )}
        {setupMode && <RoleSetupPanel roleId={visibleRole} job={jobs[visibleRole]} />}
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
