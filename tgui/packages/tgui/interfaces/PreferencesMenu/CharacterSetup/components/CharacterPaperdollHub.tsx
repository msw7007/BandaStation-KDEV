import { CharacterPreview } from 'tgui/interfaces/common/CharacterPreview';

import { CyberButton } from './CyberInput';
import { SlotButton } from './SlotButton';

export type PaperdollSlot = {
  id: string;
  label: string;
  icon?: string;
  state?: string;
  warning?: string;
  disabled?: boolean;
};

type CharacterPaperdollHubProps = {
  previewImage?: string;
  previewId: string;
  previewScale?: number;
  previewScaleX?: number;
  previewScaleY?: number;
  slots: PaperdollSlot[];
  selectedSlot?: string;
  compact?: boolean;
  actionLabel?: string;
  actionIcon?: string;
  actionDisabled?: boolean;
  actionHint?: string;
  onSelectSlot?: (slot: string) => void;
  onAction?: () => void;
};

export function CharacterPaperdollHub(props: CharacterPaperdollHubProps) {
  const {
    actionDisabled,
    actionHint,
    actionIcon,
    compact,
    actionLabel,
    onAction,
    onSelectSlot,
    previewImage,
    previewId,
    previewScale,
    previewScaleX,
    previewScaleY,
    selectedSlot,
    slots,
  } = props;
  const midpoint = Math.ceil(slots.length / 2);
  const leftSlots = slots.slice(0, midpoint);
  const rightSlots = slots.slice(midpoint);

  const renderSlots = (slotList: PaperdollSlot[]) =>
    slotList.map((slot) => (
      <SlotButton
        key={slot.id}
        disabled={slot.disabled}
        icon={slot.icon}
        label={slot.label}
        selected={selectedSlot === slot.id}
        state={slot.state}
        warning={slot.warning}
        onClick={() => onSelectSlot?.(slot.id)}
      />
    ));

  return (
    <div className={compact ? 'CharacterPaperdollHub compact' : 'CharacterPaperdollHub'}>
      <div className="CharacterPaperdollHub__slots CharacterPaperdollHub__slots--left">
        {renderSlots(leftSlots)}
      </div>
      <div className="CharacterPaperdollHub__preview">
        <CharacterPreview
          height={compact ? '260px' : '360px'}
          id={previewId}
          imageBase64={previewImage}
          scale={previewScale}
          scaleX={previewScaleX}
          scaleY={previewScaleY}
          transparent
          width={compact ? '200px' : undefined}
        />
      </div>
      <div className="CharacterPaperdollHub__slots CharacterPaperdollHub__slots--right">
        {renderSlots(rightSlots)}
      </div>
      {!!actionLabel && (
        <div className="CharacterPaperdollHub__action" title={actionHint}>
          <CyberButton
            disabled={actionDisabled}
            icon={actionIcon}
            onClick={onAction}
          >
            {actionLabel}
          </CyberButton>
        </div>
      )}
    </div>
  );
}
