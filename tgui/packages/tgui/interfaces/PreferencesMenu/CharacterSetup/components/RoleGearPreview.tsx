import type { CyberpunkRole, Job, RoleOutfitItem } from '../../types';
import { CharacterPreview } from '../../../common/CharacterPreview';
import { CyberSectionHeader } from './CyberPanel';
import { ItemCard } from './ItemCard';
import { roleDisplayName } from './RoleCard';

type RoleGearPreviewProps = {
  roleId?: string;
  job?: Job;
  previewId?: string;
};

const corporationText: Record<string, string> = {
  benn: 'Бэнь',
  ryaznov: 'Рязнов',
  starlight: 'Старлайт',
};

function groupOutfitItems(items: RoleOutfitItem[]) {
  const grouped: Record<string, RoleOutfitItem[]> = {};
  for (const item of items) {
    grouped[item.slot] ||= [];
    grouped[item.slot].push(item);
  }
  return grouped;
}

function roleDirection(cyberRole?: CyberpunkRole) {
  if (!cyberRole) {
    return 'Свободные';
  }

  if (cyberRole.corporation) {
    return corporationText[cyberRole.corporation] || cyberRole.corporation;
  }

  if (
    cyberRole.role_class === 'government' ||
    cyberRole.role_class === 'council' ||
    cyberRole.role_class === 'officer'
  ) {
    return 'Правительство';
  }

  return 'Свободные';
}

function maxSlots(job: Job) {
  if (job.total_positions === undefined) {
    return 'не задано';
  }
  if (job.total_positions < 0) {
    return 'без лимита';
  }
  return String(job.total_positions);
}

function hasFixedSalary(cyberRole?: CyberpunkRole) {
  return (
    !!cyberRole?.corporation ||
    cyberRole?.role_class === 'government' ||
    cyberRole?.role_class === 'council' ||
    cyberRole?.role_class === 'officer'
  );
}

function salaryText(job: Job, cyberRole?: CyberpunkRole) {
  if (!hasFixedSalary(cyberRole)) {
    return 'нет фиксированной';
  }
  return job.paycheck !== undefined ? `${job.paycheck} cr` : 'не задана';
}

function isCorporateCombat(cyberRole?: CyberpunkRole) {
  return !!cyberRole?.corporation && cyberRole.role_class === 'agent';
}

function bonusRows(cyberRole?: CyberpunkRole) {
  if (!cyberRole) {
    return ['+6 свободных очков навыков'];
  }

  if (cyberRole.corporation) {
    if (isCorporateCombat(cyberRole)) {
      return [
        '+2 к характеристикам: две разные по роли',
        '+2 свободных очка навыков',
        '+2 очка боевых навыков',
      ];
    }

    return [
      '+2 к характеристикам: две разные по роли',
      '+4 свободных очка навыков',
    ];
  }

  if (cyberRole.group === 'mercenary') {
    return ['+4 очка боевых навыков', '+2 свободных очка навыков'];
  }

  return ['+6 свободных очков навыков'];
}

export function RoleGearPreview(props: RoleGearPreviewProps) {
  const { job, previewId, roleId } = props;
  const outfitItems = job?.outfit_items || [];
  const groupedItems = groupOutfitItems(outfitItems);
  const cyberRole = job?.cyberpunk_role;

  if (!roleId || !job) {
    return (
      <div className="RoleGearPreview empty">
        Выберите роль, чтобы увидеть направление, лимиты, бонусы и выдаваемый набор.
      </div>
    );
  }

  return (
    <div className="RoleGearPreview">
      <div className="RoleGearPreview__doll">
        <div className="RoleGearPreview__portraitTitle">{roleDisplayName(roleId)}</div>
        {!!previewId && (
          <CharacterPreview
            height="180px"
            id={previewId}
            transparent
            width="220px"
          />
        )}
      </div>

      <div className="RoleGearPreview__body">
        <div className="RoleGearPreview__summaryStrip">
          <span>
            <b>Направление</b>
            {roleDirection(cyberRole)}
          </span>
          <span>
            <b>Максимум слотов</b>
            {maxSlots(job)}
          </span>
          <span>
            <b>Фиксированная зарплата</b>
            {salaryText(job, cyberRole)}
          </span>
          {!!cyberRole?.bonus_credits && (
            <span>
              <b>Стартовые кредиты</b>
              {cyberRole.bonus_credits} cr
            </span>
          )}
        </div>

      <CyberSectionHeader>Бонусы роли</CyberSectionHeader>
      <div className="RoleGearPreview__bonusList">
        {bonusRows(cyberRole).map((bonus) => (
          <span key={bonus}>{bonus}</span>
        ))}
      </div>

      <CyberSectionHeader>Выдаваемые вещи</CyberSectionHeader>
      <div className="RoleGearPreview__grid">
        {Object.entries(groupedItems).map(([slot, items]) => (
          <div key={slot} className="RoleGearPreview__slot">
            <b>{slot}</b>
            {items.map((item, index) => (
              <ItemCard
                key={`${slot}-${item.item_type}-${index}`}
                name={item.item_name}
                icon={item.icon}
                iconState={item.icon_state}
                meta={item.guaranteed ? item.source : `${item.source} / попытка`}
                tags={item.warning ? [item.warning] : undefined}
              />
            ))}
          </div>
        ))}
      </div>
      </div>
    </div>
  );
}
