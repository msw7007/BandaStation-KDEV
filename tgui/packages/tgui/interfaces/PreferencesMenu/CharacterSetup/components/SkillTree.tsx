import type {
  CharacterSetupRuntimeSkill,
  CharacterSetupSkill,
} from '../../types';
import { PerkNode } from './PerkNode';

type SkillTreeProps = {
  skills: CharacterSetupSkill[];
  runtimeSkills?: Record<string, CharacterSetupRuntimeSkill>;
  attributeId?: string;
  compact?: boolean;
};

export function SkillTree(props: SkillTreeProps) {
  const { attributeId, compact, runtimeSkills, skills } = props;
  const shownSkills = attributeId
    ? skills.filter((skill) => skill.attribute_id === attributeId)
    : skills;

  return (
    <div className={compact ? 'SkillTree compact' : 'SkillTree'}>
      {shownSkills.map((skill) => {
        const runtime = runtimeSkills?.[skill.id];
        const disabledReason = runtime?.disabled_reason;
        const isWeaponSkill = skill.kind === 'weapon';
        return (
          <div key={skill.id} className="SkillTree__branch" title={disabledReason}>
            <header>
              <b>{skill.name}</b>
              <span>
                {runtime?.level || 0}/{skill.max_character_level}
              </span>
            </header>
            {skill.perks.length ? (
              <div className="SkillTree__perks">
                {skill.perks.map((perk) => (
                  <PerkNode
                    key={perk.index}
                    disabled
                    name={perk.name}
                    description={perk.description}
                    maxRank={perk.max_rank}
                    rank={runtime?.perks?.[String(perk.index)] || 0}
                  />
                ))}
              </div>
            ) : isWeaponSkill ? (
              <div className="SkillTree__weapon">
                <span>Уровень: {runtime?.level || 0}</span>
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
