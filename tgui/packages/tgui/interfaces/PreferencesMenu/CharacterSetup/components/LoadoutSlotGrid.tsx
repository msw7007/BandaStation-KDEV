import { SlotButton } from './SlotButton';

const equipmentSlots = [
  ['hand_l', 'Левая рука', 'hand-paper'],
  ['hand_r', 'Правая рука', 'hand-rock'],
  ['pocket_l', 'Карман Л', 'box'],
  ['pocket_r', 'Карман П', 'box'],
  ['belt', 'Пояс', 'circle-notch'],
  ['shoulder_l', 'Левое плечо', 'bag-shopping'],
  ['shoulder_r', 'Правое плечо', 'bag-shopping'],
  ['head', 'Голова', 'helmet-safety'],
  ['mask', 'Маска', 'mask'],
  ['glasses', 'Очки', 'glasses'],
  ['finger', 'Палец', 'ring'],
  ['gloves', 'Перчатки', 'mitten'],
  ['bracers', 'Нарукавник', 'shield-halved'],
  ['shoes', 'Сапоги', 'shoe-prints'],
  ['pants', 'Штаны', 'person'],
  ['uniform', 'Костюм', 'shirt'],
  ['suit', 'Верхняя одежда', 'vest'],
  ['hair', 'Волосы', 'scissors'],
  ['ears', 'Уши', 'headphones'],
  ['tights', 'Колготки', 'socks'],
  ['underwear', 'Трусы', 'person'],
  ['chest', 'Грудь', 'id-card'],
];

type LoadoutSlotGridProps = {
  selectedSlot?: string;
  disabled?: boolean;
  onSelect?: (slot: string) => void;
};

export function LoadoutSlotGrid(props: LoadoutSlotGridProps) {
  const { disabled, onSelect, selectedSlot } = props;
  return (
    <div className="LoadoutSlotGrid">
      {equipmentSlots.map(([id, label, icon]) => (
        <SlotButton
          key={id}
          disabled={disabled}
          icon={icon}
          label={label}
          selected={selectedSlot === id}
          state={disabled ? 'TODO' : undefined}
          warning={
            disabled
              ? 'TODO: slot assignment needs backend loadout slot support.'
              : undefined
          }
          onClick={() => onSelect?.(id)}
        />
      ))}
    </div>
  );
}

