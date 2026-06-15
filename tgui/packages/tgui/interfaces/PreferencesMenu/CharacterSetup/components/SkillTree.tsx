import { Button } from 'tgui-core/components';

import type {
  CharacterSetupRuntimePerk,
  CharacterSetupRuntimeSkill,
  CharacterSetupSkill,
} from '../../types';
import { PerkNode } from './PerkNode';

type SkillTreeProps = {
  skills: CharacterSetupSkill[];
  runtimeSkills?: Record<string, CharacterSetupRuntimeSkill>;
  attributeId?: string;
  compact?: boolean;
  onAdjustPerk?: (skillId: string, perkIndex: number, delta: number) => void;
  onAdjustSkillLevel?: (skillId: string, delta: number) => void;
};

function getRuntimePerk(
  runtime: CharacterSetupRuntimeSkill | undefined,
  perkIndex: number,
): CharacterSetupRuntimePerk {
  const rawPerk = runtime?.perks?.[String(perkIndex)];
  if (typeof rawPerk === 'number') {
    return {
      rank: rawPerk,
      can_increase: !!runtime?.editable,
      can_decrease: rawPerk > 0 && !!runtime?.editable,
    };
  }
  return {
    rank: rawPerk?.rank || 0,
    can_increase: !!rawPerk?.can_increase,
    can_decrease: !!rawPerk?.can_decrease,
  };
}

export function SkillTree(props: SkillTreeProps) {
  const {
    attributeId,
    compact,
    onAdjustPerk,
    onAdjustSkillLevel,
    runtimeSkills,
    skills,
  } = props;
  const shownSkills = attributeId
    ? skills.filter((skill) => skill.attribute_id === attributeId)
    : skills;

  return (
    <div className={compact ? 'SkillTree compact' : 'SkillTree'}>
      {shownSkills.map((skill) => {
        const runtime = runtimeSkills?.[skill.id];
        const disabledReason = runtime?.disabled_reason;
        const isWeaponSkill = skill.kind === 'weapon';
        const convertedExperience = runtime?.converted_experience || 0;
        const pendingExperience = runtime?.pending_experience || 0;
        const experienceGoal = runtime?.experience_goal || 100;
        const totalExperience = convertedExperience + pendingExperience;
        const experienceProgress = Math.min(
          100,
          Math.round((totalExperience / Math.max(experienceGoal, 1)) * 100),
        );
        return (
          <div key={skill.id} className="SkillTree__branch" title={disabledReason}>
            <header>
              <b>{skill.name}</b>
              <span>
                {runtime?.level || 0}/{skill.max_character_level}
              </span>
            </header>
            <div className="SkillTree__xp">
              <div className="SkillTree__xpTrack">
                <span style={{ width: `${experienceProgress}%` }} />
              </div>
              <small>
                XP {Math.round(totalExperience)}/{experienceGoal}
              </small>
            </div>
            {skill.perks.length ? (
              <div className="SkillTree__perks">
                {skill.perks.map((perk) => {
                  const runtimePerk = getRuntimePerk(runtime, perk.index);
                  const rank = runtimePerk.rank;
                  const locked = !runtimePerk.can_increase && !runtimePerk.can_decrease;
                  const disabled = !runtime?.editable || !onAdjustPerk;
                  return (
                    <PerkNode
                      key={perk.index}
                      disabled={disabled}
                      locked={locked}
                      name={perk.name}
                      description={perk.description}
                      rankDescriptions={perk.rank_descriptions}
                      maxRank={perk.max_rank}
                      rank={rank}
                      skillKind={skill.kind}
                      onClick={() => {
                        if (runtimePerk.can_increase) {
                          onAdjustPerk?.(skill.id, perk.index, 1);
                        }
                      }}
                      onContextMenu={(event) => {
                        event.preventDefault();
                        if (runtimePerk.can_decrease) {
                          onAdjustPerk?.(skill.id, perk.index, -1);
                        }
                      }}
                    />
                  );
                })}
              </div>
            ) : isWeaponSkill ? (
              <div className="SkillTree__weapon">
                <div className="SkillTree__weaponControl">
                  <Button
                    icon="minus"
                    disabled={
                      !runtime?.editable ||
                      !onAdjustSkillLevel ||
                      !runtime?.can_decrease ||
                      (runtime?.level || 0) <= 0
                    }
                    onClick={() => onAdjustSkillLevel?.(skill.id, -1)}
                  />
                  <div className="SkillTree__weaponTrack">
                    <span
                      style={{
                        width: `${Math.round(
                          ((runtime?.level || 0) /
                            Math.max(skill.max_character_level, 1)) *
                            100,
                        )}%`,
                      }}
                    />
                  </div>
                  <b>
                    {runtime?.level || 0}/{skill.max_character_level}
                  </b>
                  <Button
                    icon="plus"
                    disabled={
                      !runtime?.editable ||
                      !onAdjustSkillLevel ||
                      !runtime?.can_increase ||
                      (runtime?.level || 0) >= skill.max_character_level
                    }
                    onClick={() => onAdjustSkillLevel?.(skill.id, 1)}
                  />
                </div>
                <small>
                  +{Math.round((skill.weapon_damage_bonus_per_level || 0) * 100)}%
                  урона, -
                  {Math.round(
                    (skill.weapon_cooldown_reduction_per_level || 0) * 100,
                  )}
                  % отката за уровень
                </small>
              </div>
            ) : (
              <div className="SkillTree__missing">
                <span>Нет описанных перков</span>
                <small>TODO: заполнить perk_definitions для {skill.id}</small>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
