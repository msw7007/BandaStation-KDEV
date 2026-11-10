import { SlotButton } from './SlotButton';

type EquipmentSlot = [id: string, label: string, icon: string];

const equipmentSlotGroups: Record<string, EquipmentSlot[]> = {
  top: [
    ['glasses', 'Очки', 'glasses'],
    ['head', 'Голова', 'helmet-safety'],
    ['ears', 'Уши', 'headphones'],
    ['mask', 'Маска', 'mask'],
    ['neck', 'Шея / ID', 'link'],
  ],
  left: [
    ['shoulder_l', 'Левое плечо', 'bag-shopping'],
    ['hand_l', 'Левая рука', 'hand-paper'],
    ['pocket_l', 'Левый карман', 'box'],
  ],
  right: [
    ['shoulder_r', 'Правое плечо', 'bag-shopping'],
    ['hand_r', 'Правая рука', 'hand-rock'],
    ['pocket_r', 'Правый карман', 'box'],
  ],
  bottom: [
    ['suit', 'Сьют / грудь', 'vest'],
    ['uniform', 'Униформа', 'shirt'],
    ['belt', 'Пояс', 'toolbox'],
    ['pants', 'Штаны', 'person'],
    ['gloves', 'Руки', 'mitten'],
    ['shoes', 'Обувь', 'shoe-prints'],
  ],
  underwear: [
    ['bag', 'Сумка', 'briefcase'],
    ['undershirt', 'Майка', 'shirt'],
    ['underwear', 'Белье', 'person'],
    ['tights', 'Носки', 'socks'],
  ],
};

type LoadoutSlotGridProps = {
  selectedSlot?: string;
  disabled?: boolean;
  onSelect?: (slot: string) => void;
};

export function LoadoutSlotGrid(props: LoadoutSlotGridProps) {
  const { disabled, onSelect, selectedSlot } = props;
  const renderSlot = ([id, label, icon]: EquipmentSlot, region: string) => (
    <SlotButton
      key={`${region}-${id}`}
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
  );

  return (
    <div className="LoadoutSlotGrid LoadoutSlotGrid--paperdoll">
      <div className="LoadoutSlotGrid__row LoadoutSlotGrid__row--top">
        {equipmentSlotGroups.top.map((slot) => renderSlot(slot, 'top'))}
      </div>
      <div className="LoadoutSlotGrid__middle">
        <div className="LoadoutSlotGrid__side LoadoutSlotGrid__side--left">
          {equipmentSlotGroups.left.map((slot) => renderSlot(slot, 'left'))}
        </div>
        <div className="LoadoutSlotGrid__side LoadoutSlotGrid__side--right">
          {equipmentSlotGroups.right.map((slot) => renderSlot(slot, 'right'))}
        </div>
      </div>
      <div className="LoadoutSlotGrid__row LoadoutSlotGrid__row--bottom">
        {equipmentSlotGroups.bottom.map((slot) => renderSlot(slot, 'bottom'))}
      </div>
      <div className="LoadoutSlotGrid__row LoadoutSlotGrid__row--underwear">
        {equipmentSlotGroups.underwear.map((slot) =>
          renderSlot(slot, 'underwear'),
        )}
      </div>
    </div>
  );
}
