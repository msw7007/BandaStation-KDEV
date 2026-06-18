import type { MouseEvent as ReactMouseEvent, ReactNode } from 'react';
import { useRef, useState } from 'react';
import {
  Button,
  Icon,
  Input,
  TextArea,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';

type FieldShellProps = {
  label: ReactNode;
  icon?: string;
  hint?: ReactNode;
  disabled?: boolean;
  children: ReactNode;
};

function FieldShell(props: FieldShellProps) {
  const { children, disabled, hint, icon, label } = props;
  return (
    <label className={classes(['CyberField', disabled && 'disabled'])}>
      <div className="CyberField__label">
        {!!icon && <Icon name={icon} />}
        <span>{label}</span>
      </div>
      <div className="CyberField__control">{children}</div>
      {!!hint && <div className="CyberField__hint">{hint}</div>}
    </label>
  );
}

type CyberInputProps = {
  label: ReactNode;
  icon?: string;
  hint?: ReactNode;
  value?: string | number;
  disabled?: boolean;
  placeholder?: string;
  onChange?: (value: string) => void;
};

export function CyberInput(props: CyberInputProps) {
  const { disabled, hint, icon, label, onChange, placeholder, value } = props;
  return (
    <FieldShell disabled={disabled} hint={hint} icon={icon} label={label}>
      <Input
        fluid
        disabled={disabled}
        placeholder={placeholder}
        value={String(value ?? '')}
        onChange={onChange}
      />
    </FieldShell>
  );
}

type CyberNumberInputProps = Omit<CyberInputProps, 'onChange' | 'value'> & {
  value?: number;
  min?: number;
  max?: number;
  step?: number;
  onChange?: (value: number) => void;
};

export function CyberNumberInput(props: CyberNumberInputProps) {
  const { disabled, hint, icon, label, max, min, onChange, step, value } = props;
  const minValue = min ?? 0;
  const maxValue = max ?? 100;
  const stepValue = step ?? 1;
  const currentValue = value ?? minValue;
  const clamp = (nextValue: number) =>
    Math.max(minValue, Math.min(maxValue, nextValue));
  const normalize = (nextValue: number) => Number(clamp(nextValue).toFixed(3));
  const updateFromText = (nextText: string) => {
    const parsedValue = Number(nextText.replace(',', '.'));
    if (Number.isFinite(parsedValue)) {
      onChange?.(normalize(parsedValue));
    }
  };

  return (
    <FieldShell disabled={disabled} hint={hint} icon={icon} label={label}>
      <div className="CyberStepperField">
        <button
          type="button"
          disabled={disabled}
          onClick={() => onChange?.(normalize(currentValue - stepValue))}
        >
          -
        </button>
        <Input
          fluid
          disabled={disabled}
          value={String(currentValue)}
          onChange={updateFromText}
        />
        <button
          type="button"
          disabled={disabled}
          onClick={() => onChange?.(normalize(currentValue + stepValue))}
        >
          +
        </button>
      </div>
    </FieldShell>
  );
}

type CyberSliderProps = Omit<CyberNumberInputProps, 'onChange'> & {
  onChange?: (value: number) => void;
};

export function CyberSlider(props: CyberSliderProps) {
  const { disabled, hint, icon, label, max, min, onChange, step, value } = props;
  const minValue = min ?? 0;
  const maxValue = max ?? 100;
  const [draftValue, setDraftValue] = useState<number | null>(null);
  const currentValue = draftValue ?? value ?? minValue;
  const pendingValue = useRef(currentValue);
  const range = Math.max(1, maxValue - minValue);
  const percent = Math.max(
    0,
    Math.min(100, ((currentValue - minValue) / range) * 100),
  );
  const stepValue = step ?? 1;
  const updateFromClientX = (
    clientX: number,
    rect: DOMRect,
  ) => {
    if (disabled) {
      return currentValue;
    }
    const rawValue = minValue + ((clientX - rect.left) / rect.width) * range;
    const steppedValue =
      Math.round((rawValue - minValue) / stepValue) * stepValue + minValue;
    const nextValue = Math.max(minValue, Math.min(maxValue, steppedValue));
    pendingValue.current = nextValue;
    setDraftValue(nextValue);
    return nextValue;
  };
  const startDrag = (event: ReactMouseEvent<HTMLDivElement, MouseEvent>) => {
    if (disabled) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();

    const rect = event.currentTarget.getBoundingClientRect();
    updateFromClientX(event.clientX, rect);
    const onMove = (moveEvent: MouseEvent) => {
      moveEvent.preventDefault();
      updateFromClientX(moveEvent.clientX, rect);
    };
    const onUp = () => {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
      const nextValue = pendingValue.current;
      setDraftValue(null);
      onChange?.(nextValue);
    };

    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  };

  return (
    <FieldShell disabled={disabled} hint={hint} icon={icon} label={label}>
      <div
        className="CyberSlider"
        onMouseDown={startDrag}
        title="Hold LMB and drag inside the field."
      >
        <span className="CyberSlider__handle" style={{ left: `${percent}%` }} />
        <b>{Number(currentValue.toFixed(3))}</b>
      </div>
    </FieldShell>
  );
}

type CyberTextareaProps = CyberInputProps & {
  height?: number;
};

export function CyberTextarea(props: CyberTextareaProps) {
  const { disabled, height = 72, hint, icon, label, onChange, placeholder } = props;
  return (
    <FieldShell disabled={disabled} hint={hint} icon={icon} label={label}>
      <TextArea
        fluid
        height={`${height}px`}
        disabled={disabled}
        placeholder={placeholder}
        value={String(props.value ?? '')}
        onChange={onChange}
      />
    </FieldShell>
  );
}

type CyberSelectProps = CyberInputProps & {
  options: Array<{ displayText: ReactNode; value: string }>;
  selected?: string;
  onSelected?: (value: string) => void;
};

export function CyberSelect(props: CyberSelectProps) {
  const [open, setOpen] = useState(false);
  const {
    disabled,
    hint,
    icon,
    label,
    onSelected,
    options,
    selected,
    value,
  } = props;
  const current = selected ?? value;
  const displayText =
    options.find((option) => option.value === String(current ?? ''))?.displayText ??
    String(current ?? '');
  const currentIndex = options.findIndex(
    (option) => option.value === String(current ?? ''),
  );
  const canStep = !disabled && options.length > 1 && !!onSelected;
  const stepSelection = (direction: -1 | 1) => {
    if (!canStep) {
      return;
    }
    const safeIndex = currentIndex >= 0 ? currentIndex : 0;
    const nextIndex = (safeIndex + direction + options.length) % options.length;
    onSelected?.(options[nextIndex].value);
  };

  return (
    <FieldShell disabled={disabled} hint={hint} icon={icon} label={label}>
      <div className={classes(['CyberSelectStepper', open && 'open'])}>
        <button
          type="button"
          className="CyberSelectStepper__button CyberSelectStepper__button--minus"
          disabled={!canStep}
          onClick={() => stepSelection(-1)}
        >
          -
        </button>
        <div
          className="CyberSelectDropdown"
          onMouseDown={(event) => event.stopPropagation()}
        >
          <button
            type="button"
            className="CyberSelectDropdown__control"
            disabled={disabled || !options.length}
            onClick={() => setOpen(!open)}
          >
            <span>{displayText}</span>
            <Icon name={open ? 'angle-up' : 'angle-down'} />
          </button>
          {open && (
            <div className="CyberSelectDropdown__menu">
              {options.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  className={
                    String(current ?? '') === option.value ? 'selected' : ''
                  }
                  onClick={() => {
                    onSelected?.(option.value);
                    setOpen(false);
                  }}
                >
                  {option.displayText}
                </button>
              ))}
            </div>
          )}
        </div>
        <button
          type="button"
          className="CyberSelectStepper__button CyberSelectStepper__button--plus"
          disabled={!canStep}
          onClick={() => stepSelection(1)}
        >
          +
        </button>
      </div>
    </FieldShell>
  );
}

type CyberButtonProps = {
  children: ReactNode;
  icon?: string;
  disabled?: boolean;
  selected?: boolean;
  danger?: boolean;
  onClick?: () => void;
};

export function CyberButton(props: CyberButtonProps) {
  return (
    <Button
      fluid
      className={classes(['CyberButton', props.danger && 'danger'])}
      disabled={props.disabled}
      icon={props.icon}
      selected={props.selected}
      onClick={props.onClick}
    >
      {props.children}
    </Button>
  );
}

type CyberColorButtonProps = {
  label: ReactNode;
  buttonLabel?: ReactNode;
  icon?: string;
  color?: string;
  disabled?: boolean;
  onClick?: () => void;
};

export function CyberColorButton(props: CyberColorButtonProps) {
  const normalizedColor = String(props.color || 'c8c8c8');
  const swatchColor = normalizedColor.startsWith('#')
    ? normalizedColor
    : `#${normalizedColor}`;

  return (
    <FieldShell disabled={props.disabled} icon={props.icon} label={props.label}>
      <button
        type="button"
        className="CyberColorButton"
        disabled={props.disabled}
        onClick={props.onClick}
      >
        <i className="CyberColorButton__swatch" style={{ backgroundColor: swatchColor }} />
        <span>{props.buttonLabel || 'Выбрать цвет'}</span>
      </button>
    </FieldShell>
  );
}

type CyberToggleProps = {
  label: string;
  checked: boolean;
  disabled?: boolean;
  onClick?: () => void;
};

export function CyberToggle(props: CyberToggleProps) {
  return (
    <button
      className={classes(['CyberToggle', props.checked && 'checked'])}
      disabled={props.disabled}
      onClick={props.onClick}
    >
      <span>{props.label}</span>
      <span className="CyberToggle__pill" />
    </button>
  );
}

type CyberPointControlProps = {
  label: string;
  value: number;
  min?: number;
  max?: number;
  disabled?: boolean;
  minusDisabled?: boolean;
  plusDisabled?: boolean;
  reason?: string;
  onMinus?: () => void;
  onPlus?: () => void;
};

export function CyberPointControl(props: CyberPointControlProps) {
  const { disabled, label, max, min, reason, value } = props;
  return (
    <div className={classes(['CyberPointControl', disabled && 'disabled'])}>
      <div>
        <b>{label}</b>
        {!!reason && <span>{reason}</span>}
      </div>
      <div className="CyberPointControl__buttons">
        <Button
          icon="minus"
          disabled={disabled || props.minusDisabled || (min !== undefined && value <= min)}
          onClick={props.onMinus}
        />
        <strong>{value}</strong>
        <Button
          icon="plus"
          disabled={disabled || props.plusDisabled || (max !== undefined && value >= max)}
          onClick={props.onPlus}
        />
      </div>
    </div>
  );
}

export function CyberSearch(props: {
  value: string;
  placeholder?: string;
  onChange: (value: string) => void;
}) {
  return (
    <Input
      fluid
      className="CyberSearch"
      placeholder={props.placeholder || 'Поиск...'}
      value={props.value}
      onChange={props.onChange}
    />
  );
}
