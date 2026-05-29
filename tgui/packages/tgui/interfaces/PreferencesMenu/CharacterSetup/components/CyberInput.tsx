import type { ReactNode } from 'react';
import {
  Button,
  Dropdown,
  Icon,
  Input,
  NumberInput,
  Slider,
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
  return (
    <FieldShell disabled={disabled} hint={hint} icon={icon} label={label}>
      <NumberInput
        fluid
        disabled={disabled}
        value={value ?? 0}
        minValue={min ?? 0}
        maxValue={max ?? 100}
        step={step ?? 1}
        onChange={onChange}
      />
    </FieldShell>
  );
}

type CyberSliderProps = Omit<CyberNumberInputProps, 'onChange'> & {
  onChange?: (value: number) => void;
};

export function CyberSlider(props: CyberSliderProps) {
  const { disabled, hint, icon, label, max, min, onChange, step, value } = props;
  return (
    <FieldShell disabled={disabled} hint={hint} icon={icon} label={label}>
      <div className="CyberSlider">
        <Slider
          width="100%"
          disabled={disabled}
          value={value ?? min ?? 0}
          minValue={min ?? 0}
          maxValue={max ?? 100}
          step={step ?? 1}
          stepPixelSize={8}
          onChange={(_event, newValue) => onChange?.(newValue)}
        />
        <b>{value ?? min ?? 0}</b>
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

  return (
    <FieldShell disabled={disabled} hint={hint} icon={icon} label={label}>
      <Dropdown
        buttons
        disabled={disabled || !options.length}
        displayText={displayText}
        options={options}
        selected={String(current ?? '')}
        width="100%"
        onSelected={onSelected || (() => undefined)}
      />
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
