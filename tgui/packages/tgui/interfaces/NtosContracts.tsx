// CYBERPUNK BUILD - rebuild and delete before release
import {
  type ChangeEvent,
  type MouseEvent as ReactMouseEvent,
  type ReactNode,
  useState,
} from 'react';
import { Icon } from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type ContractStats = {
  created: number;
  accepted: number;
  completed: number;
  failed: number;
  cancelled: number;
  open?: number;
  success_percent?: number;
};

type TerminalOption = {
  label: string;
  name: string;
  area: string;
  x: number;
  y: number;
  z: number;
};

type FundingOption = {
  id: number;
  name: string;
  balance: number;
};

type ReservableItem = {
  ref: string;
  name: string;
  type: string;
  tier: number;
  value: number;
};

type Contract = {
  id: number;
  title: string;
  description: string;
  type: string;
  target: string;
  status: string;
  creator: string;
  contractor?: string;
  assignedContractor?: string;
  payment: number;
  deposit: number;
  penalty: number;
  taxPaid: number;
  legal: BooleanLike;
  public: BooleanLike;
  corporation?: string;
  creatorConfirmRequired: BooleanLike;
  directAccessCode?: string;
  requiredAmount: number;
  deliveredAmount: number;
  requiredPercent: number;
  conditions?: ContractCondition[];
  failureConditions?: ContractCondition[];
  evidenceDisclosed?: BooleanLike;
  evidenceSummary?: string;
  deadline: string;
  canAccept: BooleanLike;
  canRefuse: BooleanLike;
  canManage: BooleanLike;
  canAct: BooleanLike;
  contractorStats?: ContractStats;
  history?: string[];
};

type ContractCondition = {
  id: string;
  name: string;
  description?: string;
  target?: string;
  targetArea?: string;
  targetType?: string;
  targetX?: number;
  targetY?: number;
  targetZ?: number;
  targetRadius?: number;
  requiredAmount?: number;
  deliveredAmount?: number;
  requiredPercent?: number;
  minimumQuality?: number;
  minimumRarity?: number;
  destinationKind?: string;
  destination?: string;
  targetKind?: string;
  sabotageMode?: string;
  repairMode?: string;
  guardKind?: string;
  eliminationMode?: string;
  partialPayment?: BooleanLike;
};

type Data = {
  accountName?: string;
  accountBalance: number;
  userStats: ContractStats;
  contracts: Contract[];
  offeredContracts: Contract[];
  ownedContracts: Contract[];
  acceptedContracts: Contract[];
  directContract?: Contract;
  terminalOptions?: TerminalOption[];
  fundingOptions?: FundingOption[];
  reservableItems?: ReservableItem[];
};

const contractTypes = [
  ['delivery', 'Доставка'],
  ['repair', 'Ремонт'],
  ['build', 'Стройка'],
  ['guard', 'Охрана'],
  ['mining', 'Добыча'],
  ['sabotage', 'Саботаж'],
  ['elimination', 'Устранение'],
];

const destinationKinds = [
  ['creator', 'Создатель'],
  ['recipient', 'Получатель'],
  ['terminal', 'Терминал'],
  ['coordinates', 'Координаты'],
];

const deliveryTargetKinds = [
  ['item', 'Предмет'],
  ['object', 'Объект'],
  ['mob', 'Кукла/цель'],
  ['cargo', 'Груз'],
];

const repairModes = [
  ['integrity', 'Прочность'],
  ['functional', 'Функциональность'],
];

const guardKinds = [
  ['target', 'Цель'],
  ['area', 'Зона'],
  ['cargo', 'Груз'],
];

const sabotageModes = [
  ['damage', 'Повредить'],
  ['disabled', 'Отключить'],
  ['unpowered', 'Обесточить'],
  ['broken', 'Сломать'],
  ['hacked', 'Взломать'],
  ['emagged', 'Emag'],
  ['destroyed', 'Уничтожить'],
];

const eliminationModes = [
  ['critical', 'Крит'],
  ['dead', 'Смерть'],
  ['incapacitated', 'Выведен из строя'],
  ['removed', 'Выведен из раунда'],
];

function contractTypeLabel(type: string) {
  return contractTypes.find(([value]) => value === type)?.[1] || type || '-';
}

function boolLabel(value: BooleanLike) {
  return value ? 'да' : 'нет';
}

function toneClass(tone?: 'base' | 'good' | 'bad') {
  if (tone === 'good') {
    return 'StyleGuide__textGood';
  }
  if (tone === 'bad') {
    return 'StyleGuide__textBad';
  }
  return 'StyleGuide__textBase';
}

function statusTone(status: string): 'base' | 'good' | 'bad' {
  if (['completed', 'accepted'].includes(status)) {
    return 'good';
  }
  if (['failed', 'cancelled', 'expired'].includes(status)) {
    return 'bad';
  }
  return 'base';
}

function moneyText(value: number) {
  return `${formatMoney(value || 0)} кр`;
}

function numInputHandler(setter: (value: number) => void) {
  return (event: ChangeEvent<HTMLInputElement>) =>
    setter(Number(event.currentTarget.value) || 0);
}

const Dropdown = (props: {
  options: [string, string][];
  selected: string;
  onSelected: (value: string) => void;
}) => {
  const [open, setOpen] = useState(false);
  const selectedLabel =
    props.options.find(([value]) => value === props.selected)?.[1] ||
    props.selected;

  return (
    <div className="StyleGuide__dropdown">
      <button
        type="button"
        className="StyleGuide__dropdownControl"
        onClick={() => setOpen(!open)}
      >
        <span>{selectedLabel}</span>
        <Icon name="chevron-down" />
      </button>
      {open && (
        <div className="StyleGuide__dropdownMenu">
          {props.options.map(([value, label]) => (
            <button
              key={value}
              type="button"
              className={props.selected === value ? 'selected' : ''}
              onClick={() => {
                props.onSelected(value);
                setOpen(false);
              }}
            >
              {label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

const DragField = (props: {
  label: string;
  value: number;
  min?: number;
  max?: number;
  step?: number;
  tone?: 'base' | 'good' | 'bad';
  formatValue?: (value: number) => string;
  onChange: (value: number) => void;
}) => {
  const [draftValue, setDraftValue] = useState<number | null>(null);
  const min = props.min ?? 0;
  const max = props.max ?? 100;
  const step = props.step ?? 1;
  const range = Math.max(1, max - min);
  const clampValue = (value: number) => Math.max(min, Math.min(max, value));
  const snapValue = (value: number) =>
    clampValue(Math.round(value / step) * step);
  const currentValue = clampValue(draftValue ?? props.value ?? min);
  const currentPercent = ((currentValue - min) / range) * 100;

  const startDrag = (event: ReactMouseEvent<HTMLDivElement, MouseEvent>) => {
    event.preventDefault();
    event.stopPropagation();

    const rect = event.currentTarget.getBoundingClientRect();
    let nextValue = currentValue;
    const updateValue = (clientX: number) => {
      nextValue = snapValue(min + ((clientX - rect.left) / rect.width) * range);
      setDraftValue(nextValue);
    };
    const onMove = (moveEvent: MouseEvent) => updateValue(moveEvent.clientX);
    const onUp = () => {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
      setDraftValue(null);
      props.onChange(nextValue);
    };

    updateValue(event.clientX);
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  };

  return (
    <div
      className={[
        'StyleGuide__dragField',
        props.tone === 'bad' && 'StyleGuide__dragField--red',
        props.tone === 'good' && 'StyleGuide__dragField--cyan',
      ]
        .filter(Boolean)
        .join(' ')}
      onMouseDown={startDrag}
      title="Удерживайте ЛКМ и тяните внутри поля."
    >
      <div
        className="StyleGuide__dragFieldHandle"
        style={{ left: `${currentPercent}%` }}
      />
      <div className="StyleGuide__dragFieldContent">
        <span>{props.label}</span>
        <b>{props.formatValue ? props.formatValue(currentValue) : currentValue}</b>
      </div>
    </div>
  );
};

export const NtosContracts = () => {
  const { data } = useBackend<Data>();
  const {
    accountName,
    accountBalance,
    userStats,
    contracts = [],
    offeredContracts = [],
    ownedContracts = [],
    acceptedContracts = [],
    directContract,
  } = data;
  const [tab, setTab] = useState('accepted');

  return (
    <NtosWindow width={860} height={760}>
      <NtosWindow.Content scrollable className="CyberpunkPanel StyleGuide">
        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Аккаунт</div>
          <div className="StyleGuide__formGrid">
            <dl className="StyleGuide__definitionGrid">
              <dt>ID счет</dt>
              <dd>{accountName || 'ID счет не найден'}</dd>
              <dt>Баланс</dt>
              <dd>{formatMoney(accountBalance)} кр</dd>
            </dl>
            <dl className="StyleGuide__definitionGrid">
              <dt>Создано</dt>
              <dd>{userStats?.created || 0}</dd>
              <dt>Принято</dt>
              <dd>{userStats?.accepted || 0}</dd>
              <dt>Готово / провал</dt>
              <dd>
                {userStats?.completed || 0} / {userStats?.failed || 0}
              </dd>
              <dt>Открыто / успех</dt>
              <dd>
                {userStats?.open || 0} / {userStats?.success_percent || 0}%
              </dd>
            </dl>
          </div>
        </div>

        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Контракты</div>
          <div className="StyleGuide__topTabSwitch">
            {[
              ['accepted', 'Мои', 'clipboard-check'],
              ['board', 'Доска', 'table-list'],
              ['create', 'Создать', 'file-signature'],
            ].map(([id, label, icon]) => (
              <button
                key={id}
                type="button"
                className={tab === id ? 'active' : ''}
                onClick={() => setTab(id)}
              >
                <Icon name={icon} />
                <span>{label}</span>
              </button>
            ))}
          </div>
        </div>

        {tab === 'accepted' && (
          <>
            <ContractList title="Входящие предложения" contracts={offeredContracts} />
            <ContractList title="Принятые контракты" contracts={acceptedContracts} />
            <ContractList title="Созданные мной" contracts={ownedContracts} />
          </>
        )}
        {tab === 'board' && (
          <BoardView contracts={contracts} directContract={directContract} />
        )}
        {tab === 'create' && <ContractCreation disabled={!accountName} />}
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const BoardView = (props: { contracts: Contract[]; directContract?: Contract }) => {
  const [boardTab, setBoardTab] = useState('public');

  return (
    <div className="StyleGuide__blockShell">
      <div className="StyleGuide__blockTitle">Доска контрактов</div>
      <div className="StyleGuide__textSwitch">
        <button
          type="button"
          className={boardTab === 'public' ? 'active' : ''}
          onClick={() => setBoardTab('public')}
        >
          Публичные
        </button>
        <button
          type="button"
          className={boardTab === 'direct' ? 'active' : ''}
          onClick={() => setBoardTab('direct')}
        >
          Прямой доступ
        </button>
      </div>
      {boardTab === 'public' ? (
        <ContractBoard contracts={props.contracts} />
      ) : (
        <DirectContract contract={props.directContract} />
      )}
    </div>
  );
};

const DirectContract = (props: { contract?: Contract }) => {
  const { act } = useBackend<Data>();
  const [contractId, setContractId] = useState('');
  return (
    <div className="StyleGuide__innerPanel">
      <div className="StyleGuide__blockTitle">Прямой доступ</div>
      <div className="StyleGuide__formGrid">
        <input
          className="StyleGuide__textInput StyleGuide__textInput--cyan"
          placeholder="ID контракта или приватный код"
          value={contractId}
          onChange={(event) => setContractId(event.currentTarget.value)}
        />
        <button
          type="button"
          className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
          onClick={() => act('direct_lookup', { id: contractId })}
        >
          <Icon name="search" />
          <span>Открыть</span>
        </button>
      </div>
      {!!props.contract && (
        <div className="StyleGuide__listStack">
          <div className="StyleGuide__blockTitle">Найденный контракт</div>
          <ContractDetails contract={props.contract} />
        </div>
      )}
    </div>
  );
};

const ContractBoard = (props: { contracts: Contract[] }) => {
  const contracts = props.contracts || [];
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const selectedContract =
    contracts.find((contract) => contract.id === selectedId) || contracts[0];

  return (
    <div className="StyleGuide__innerPanel">
      <div className="StyleGuide__blockTitle">
        Публичные контракты ({contracts.length})
      </div>
      <div className="StyleGuide__masterDetail">
        <div className="StyleGuide__masterList">
          {contracts.map((contract) => (
            <button
              key={contract.id}
              type="button"
              className={[
                'StyleGuide__dataCard',
                selectedContract?.id === contract.id && 'active',
              ]
                .filter(Boolean)
                .join(' ')}
              onClick={() => setSelectedId(contract.id)}
            >
              <div className="StyleGuide__dataCardContent">
                <div className="StyleGuide__dataCardTitle">
                  <b>
                    #{contract.id} {contract.title}
                  </b>
                  <small className={toneClass('good')}>{moneyText(contract.payment)}</small>
                </div>
                <div className="StyleGuide__miniMeta">
                  <span>{contractTypeLabel(contract.type)}</span>
                  <span className={toneClass(statusTone(contract.status))}>
                    {contract.status}
                  </span>
                </div>
                <span>{contract.target}</span>
              </div>
            </button>
          ))}
          {!contracts.length && (
            <div className="StyleGuide__placeholder">Контрактов нет.</div>
          )}
        </div>
        <div className="StyleGuide__detailPane">
          {selectedContract ? (
            <ContractDetails contract={selectedContract} />
          ) : (
            <div className="StyleGuide__placeholder">
              Выберите контракт слева.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

const ContractList = (props: { title: string; contracts: Contract[] }) => {
  const { contracts = [] } = props;
  return (
    <div className="StyleGuide__blockShell">
      <div className="StyleGuide__blockTitle">
        {props.title} ({contracts.length})
      </div>
      <div className="StyleGuide__listStack">
        {contracts.map((contract) => (
          <ContractDetails key={contract.id} contract={contract} collapsed />
        ))}
        {!contracts.length && (
          <div className="StyleGuide__placeholder">Контрактов нет.</div>
        )}
      </div>
    </div>
  );
};

const ContractDetails = (props: { contract: Contract; collapsed?: boolean }) => {
  const { contract } = props;
  const content = (
    <>
      <ContractActions contract={contract} />
      <div className="StyleGuide__contractMatrix">
        <ContractCell
          label="Статус"
          value={contract.status}
          tone={statusTone(contract.status)}
        />
        <ContractCell label="Тип" value={contractTypeLabel(contract.type)} />
        <ContractCell label="Цель" value={contract.target} />
        <ContractCell label="Оплата" value={moneyText(contract.payment)} tone="good" />
        <ContractCell label="Создатель" value={contract.creator} />
        <ContractCell
          label="Источник"
          value={
            contract.corporation
              ? `корпорация / ${contract.corporation}`
              : contract.legal
                ? 'легальный'
                : 'теневой'
          }
          tone={contract.legal ? 'good' : 'bad'}
        />
        <ContractCell
          label="Исполнитель"
          value={contract.contractor || contract.assignedContractor || 'любой'}
        />
        <ContractCell
          label="Срок"
          value={contract.deadline}
          tone={contract.deadline === 'expired' ? 'bad' : 'base'}
        />
        <ContractCell label="Депозит" value={moneyText(contract.deposit)} />
        <ContractCell
          label="Штраф"
          value={moneyText(contract.penalty)}
          tone={contract.penalty > 0 ? 'bad' : 'base'}
        />
        <ContractCell
          label="Налог"
          value={moneyText(contract.taxPaid)}
          tone={contract.taxPaid > 0 ? 'bad' : 'base'}
        />
        <ContractCell
          label="Условие"
          value={`${contract.deliveredAmount}/${contract.requiredAmount}, ${contract.requiredPercent}%`}
          tone={contract.deliveredAmount >= contract.requiredAmount ? 'good' : 'base'}
        />
        <ContractCell
          label="Доказательство"
          value={contract.evidenceDisclosed ? 'раскрыто' : contract.legal ? 'гражданское' : 'криминальное'}
          tone={contract.evidenceDisclosed ? 'bad' : 'base'}
        />
        {!!contract.directAccessCode && (
          <ContractCell
            label="Приватный код"
            value={contract.directAccessCode}
            tone="good"
          />
        )}
      </div>
      {!!contract.description && (
        <div className="StyleGuide__trapezoidNote">{contract.description}</div>
      )}
      {!!contract.conditions?.length && (
        <details>
          <summary>Условия выполнения</summary>
          {contract.conditions.map((condition) => (
            <div key={condition.id} className="StyleGuide__trapezoidNote">
              {condition.name}: {condition.target || '-'}
              {condition.targetType ? ` / ${condition.targetType}` : ''}
              {condition.targetArea ? ` / ${condition.targetArea}` : ''}
            </div>
          ))}
        </details>
      )}
      {!!contract.failureConditions?.length && (
        <details>
          <summary>Условия провала</summary>
          {contract.failureConditions.map((condition) => (
            <div key={condition.id} className="StyleGuide__trapezoidNote">
              {condition.name}: {condition.description || '-'}
            </div>
          ))}
        </details>
      )}
      {!!contract.evidenceSummary && (
        <div className="StyleGuide__trapezoidNote">{contract.evidenceSummary}</div>
      )}
      {!!contract.history?.length && !props.collapsed && (
        <details>
          <summary>История</summary>
          {contract.history.map((entry, index) => (
            <div key={index} className="StyleGuide__trapezoidNote">
              {entry}
            </div>
          ))}
        </details>
      )}
    </>
  );

  return (
    <article className="StyleGuide__dataCard">
      <div className="StyleGuide__dataCardContent">
        <div className="StyleGuide__dataCardTitle">
          <b>
            #{contract.id} {contract.title}
          </b>
          <small className={toneClass('good')}>{moneyText(contract.payment)}</small>
        </div>
        {props.collapsed ? <details>{content}</details> : content}
      </div>
    </article>
  );
};

const ContractCell = (props: {
  label: string;
  value: ReactNode;
  tone?: 'base' | 'good' | 'bad';
}) => (
  <div className="StyleGuide__contractCell">
    <span>{props.label}</span>
    <b className={toneClass(props.tone)}>{props.value}</b>
  </div>
);

const ContractActions = (props: { contract: Contract }) => {
  const { act } = useBackend<Data>();
  const { contract } = props;
  return (
    <div className="StyleGuide__actionRow">
      {!!contract.canAccept && (
        <button
          type="button"
          className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
          onClick={() => act('accept', { id: contract.id })}
        >
          <Icon name="handshake" />
          <span>Принять</span>
        </button>
      )}
      {!!contract.canRefuse && (
        <button
          type="button"
          className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
          onClick={() => act('refuse_offer', { id: contract.id })}
        >
          <Icon name="times" />
          <span>Отказать</span>
        </button>
      )}
      {!!contract.canAct && (
        <>
          <button
            type="button"
            className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
            onClick={() => act('mark_held', { id: contract.id })}
          >
            <Icon name="tag" />
            <span>Пометить</span>
          </button>
          <button
            type="button"
            className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
            onClick={() => act('submit_held', { id: contract.id })}
          >
            <Icon name="box" />
            <span>Сдать</span>
          </button>
          <button
            type="button"
            className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
            onClick={() => act('check_target', { id: contract.id })}
          >
            <Icon name="search" />
            <span>Проверить</span>
          </button>
          <button
            type="button"
            className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
            onClick={() => act('abandon', { id: contract.id })}
          >
            <Icon name="ban" />
            <span>Бросить</span>
          </button>
        </>
      )}
      {!!contract.canManage && (
        <>
          <button
            type="button"
            className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
            onClick={() => act('creator_complete', { id: contract.id })}
          >
            <Icon name="check" />
            <span>Подтвердить</span>
          </button>
          <button
            type="button"
            className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
            onClick={() => act('cancel', { id: contract.id })}
          >
            <Icon name="times" />
            <span>Отменить</span>
          </button>
        </>
      )}
      {(!!contract.canManage || !!contract.canAct) && !contract.evidenceDisclosed && (
        <button
          type="button"
          className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
          onClick={() => act('disclose_evidence', { id: contract.id })}
        >
          <Icon name="balance-scale" />
          <span>Раскрыть</span>
        </button>
      )}
    </div>
  );
};

const Toggle = (props: {
  label: string;
  checked: boolean;
  onClick: () => void;
}) => (
  <button
    type="button"
    className={[
      'StyleGuide__switch',
      props.checked && 'active',
    ]
      .filter(Boolean)
      .join(' ')}
    onClick={props.onClick}
  >
    <span>{props.label}</span>
    <span className="StyleGuide__switchMark" />
  </button>
);

const Field = (props: {
  label: string;
  children: ReactNode;
  tone?: 'base' | 'good' | 'bad';
}) => (
  <label
    className={[
      'StyleGuide__formField',
      props.tone && `StyleGuide__formField--${props.tone}`,
    ]
      .filter(Boolean)
      .join(' ')}
  >
    <span>{props.label}</span>
    {props.children}
  </label>
);

const ContractCreation = (props: { disabled: boolean }) => {
  const { act, data } = useBackend<Data>();
  const terminalOptions = data.terminalOptions || [];
  const fundingOptions = data.fundingOptions || [];
  const reservableItems = data.reservableItems || [];
  const [fundingBusinessId, setFundingBusinessId] = useState(0);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [target, setTarget] = useState('');
  const [assignedContractor, setAssignedContractor] = useState('');
  const [contractType, setContractType] = useState('delivery');
  const [payment, setPayment] = useState(100);
  const [deposit, setDeposit] = useState(0);
  const [penalty, setPenalty] = useState(0);
  const [duration, setDuration] = useState(30);
  const [requiredAmount, setRequiredAmount] = useState(1);
  const [requiredPercent, setRequiredPercent] = useState(75);
  const [targetArea, setTargetArea] = useState('');
  const [targetType, setTargetType] = useState('');
  const [targetX, setTargetX] = useState(0);
  const [targetY, setTargetY] = useState(0);
  const [targetZ, setTargetZ] = useState(0);
  const [targetRadius, setTargetRadius] = useState(0);
  const [minimumQuality, setMinimumQuality] = useState(0);
  const [minimumRarity, setMinimumRarity] = useState(0);
  const [deliveryTargetKind, setDeliveryTargetKind] = useState('item');
  const [destinationKind, setDestinationKind] = useState('creator');
  const [destination, setDestination] = useState('');
  const [repairMode, setRepairMode] = useState('integrity');
  const [guardKind, setGuardKind] = useState('target');
  const [sabotageMode, setSabotageMode] = useState('damage');
  const [eliminationMode, setEliminationMode] = useState('critical');
  const [legal, setLegal] = useState(true);
  const [isPublic, setPublic] = useState(true);
  const [creatorConfirm, setCreatorConfirm] = useState(false);
  const [reservedItemRef, setReservedItemRef] = useState('');
  const [partialGuardPayment, setPartialGuardPayment] = useState(false);
  const isDelivery = contractType === 'delivery';
  const isMining = contractType === 'mining';
  const isRepair = contractType === 'repair';
  const isBuild = contractType === 'build';
  const isGuard = contractType === 'guard';
  const isSabotage = contractType === 'sabotage';
  const usesLocation = (isDelivery && destinationKind === 'coordinates') || isRepair || isBuild || isGuard || isSabotage;
  const usesQuality = isDelivery || isMining;
  const usesThreshold = isRepair || isBuild || isSabotage;
  const usesAmount = isDelivery || isMining || isGuard;
  const cleanDestination = isDelivery ? destination : '';
  const effectiveReservedItemRef = reservedItemRef || reservableItems[0]?.ref || '';
  const selectedReservedItem = reservableItems.find((item) => item.ref === effectiveReservedItemRef);
  const deliveryNeedsReservedItem = isDelivery && ['item', 'cargo'].includes(deliveryTargetKind);
  const creationDisabled = props.disabled || (deliveryNeedsReservedItem && !selectedReservedItem);

  return (
    <div className="StyleGuide__blockShell">
      <div className="StyleGuide__blockTitle">Создать контракт</div>

      <div className="StyleGuide__createLayout">
        <div className="StyleGuide__innerPanel StyleGuide__createPanel">
          <div className="StyleGuide__blockTitle">Основа</div>
          <div className="StyleGuide__formGrid">
            <Field label="Название">
              <input
                className="StyleGuide__textInput StyleGuide__textInput--cyan"
                value={title}
                onChange={(event) => setTitle(event.currentTarget.value)}
              />
            </Field>
            <Field label="Вид">
              <Dropdown
                options={contractTypes}
                selected={contractType}
                onSelected={setContractType}
              />
            </Field>
            <Field label="Цель">
              <input
                className="StyleGuide__textInput StyleGuide__textInput--cyan"
                value={target}
                onChange={(event) => setTarget(event.currentTarget.value)}
              />
            </Field>
            <Field label="Исполнитель">
              <input
                className="StyleGuide__textInput StyleGuide__textInput--cyan"
                placeholder="необязательно"
                value={assignedContractor}
                onChange={(event) => setAssignedContractor(event.currentTarget.value)}
              />
            </Field>
          </div>

          <Field label="Описание">
            <textarea
              className="StyleGuide__textInput StyleGuide__textInput--cyan"
              value={description}
              onChange={(event) => setDescription(event.currentTarget.value)}
            />
          </Field>
        </div>

        <div className="StyleGuide__innerPanel StyleGuide__createPanel">
          <div className="StyleGuide__blockTitle">Оплата</div>
          {!!fundingOptions.length && (
            <div className="StyleGuide__textSwitch StyleGuide__textSwitch--vertical">
              {fundingOptions.map((option) => (
                <button
                  key={option.id}
                  type="button"
                  className={fundingBusinessId === option.id ? 'active' : ''}
                  onClick={() => setFundingBusinessId(option.id)}
                >
                  {option.name} / {formatMoney(option.balance)} кр
                </button>
              ))}
            </div>
          )}
          {!fundingOptions.length && (
            <div className="StyleGuide__trapezoidNote">
              Личный счет / {formatMoney(data.accountBalance)} кр
            </div>
          )}
          <div className="StyleGuide__moneyGrid">
            <Field label="Оплата" tone="good">
              <input
                className="StyleGuide__textInput StyleGuide__textInput--cyan"
                type="number"
                min={0}
                value={payment}
                onChange={numInputHandler(setPayment)}
              />
            </Field>
            <Field label="Депозит">
              <input
                className="StyleGuide__textInput"
                type="number"
                min={0}
                value={deposit}
                onChange={numInputHandler(setDeposit)}
              />
            </Field>
            <Field label="Штраф" tone="bad">
              <input
                className="StyleGuide__textInput StyleGuide__textInput--red"
                type="number"
                min={0}
                value={penalty}
                onChange={numInputHandler(setPenalty)}
              />
            </Field>
          </div>
          <div className="StyleGuide__sliderStack">
            <DragField
              label="Срок"
              value={duration}
              min={1}
              max={180}
              step={1}
              formatValue={(value) => `${value} мин`}
              onChange={setDuration}
            />
          </div>
        </div>
      </div>

      <div className="StyleGuide__innerPanel StyleGuide__createPanel">
        <div className="StyleGuide__blockTitle">
          Детали: {contractTypeLabel(contractType)}
        </div>
        <div className="StyleGuide__formGrid">
          {(isBuild || isRepair || isSabotage) && (
            <Field label="Typepath цели">
              <input className="StyleGuide__textInput" value={targetType} onChange={(event) => setTargetType(event.currentTarget.value)} />
            </Field>
          )}
          {isDelivery && (
            <Field label="Тип доставки">
              <Dropdown
                options={deliveryTargetKinds}
                selected={deliveryTargetKind}
                onSelected={setDeliveryTargetKind}
              />
            </Field>
          )}
          {isRepair && (
            <Field label="Критерий ремонта">
              <Dropdown
                options={repairModes}
                selected={repairMode}
                onSelected={setRepairMode}
              />
            </Field>
          )}
          {isGuard && (
            <Field label="Что охранять">
              <Dropdown
                options={guardKinds}
                selected={guardKind}
                onSelected={setGuardKind}
              />
            </Field>
          )}
          {contractType === 'elimination' && (
            <Field label="Критерий устранения">
              <Dropdown
                options={eliminationModes}
                selected={eliminationMode}
                onSelected={setEliminationMode}
              />
            </Field>
          )}
        </div>
        <div className="StyleGuide__sliderStack">
          {usesAmount && (
            <DragField
              label="Количество"
              value={requiredAmount}
              min={1}
              max={100}
              step={1}
              onChange={setRequiredAmount}
            />
          )}
          {usesThreshold && (
            <DragField
              label={isSabotage ? 'Порог повреждения' : 'Порог целостности'}
              value={requiredPercent}
              min={0}
              max={100}
              step={5}
              tone={isSabotage ? 'bad' : 'good'}
              formatValue={(value) => `${value}%`}
              onChange={setRequiredPercent}
            />
          )}
          {usesQuality && (
            <>
              <DragField
                label="Качество"
                value={minimumQuality}
                min={0}
                max={100}
                step={5}
                tone="good"
                onChange={setMinimumQuality}
              />
              <DragField
                label="Редкость"
                value={minimumRarity}
                min={0}
                max={10}
                step={1}
                tone="good"
                onChange={setMinimumRarity}
              />
            </>
          )}
        </div>

        {deliveryNeedsReservedItem && (
          <div className="StyleGuide__formGrid">
            <Field label="Груз">
              {!!reservableItems.length ? (
                <Dropdown
                  options={reservableItems.map((item) => [
                    item.ref,
                    `${item.name} / T${item.tier} / ${formatMoney(item.value)} cr`,
                  ])}
                  selected={effectiveReservedItemRef}
                  onSelected={setReservedItemRef}
                />
              ) : (
                <div className="StyleGuide__trapezoidNote">Нет переносимых предметов для резерва.</div>
              )}
            </Field>
          </div>
        )}

        {isDelivery && (
          <div className="StyleGuide__formGrid">
            <Field label="Куда доставить">
              <Dropdown
                options={destinationKinds}
                selected={destinationKind}
                onSelected={setDestinationKind}
              />
            </Field>
            {destinationKind === 'terminal' && !!terminalOptions.length ? (
              <Field label="Терминал">
                <Dropdown
                  options={terminalOptions.map((terminal) => [
                    terminal.label,
                    `${terminal.name} / ${terminal.area}`,
                  ])}
                  selected={destination}
                  onSelected={setDestination}
                />
              </Field>
            ) : (
              destinationKind !== 'creator' && (
                <Field label="Назначение">
                  <input className="StyleGuide__textInput" value={destination} onChange={(event) => setDestination(event.currentTarget.value)} />
                </Field>
              )
            )}
          </div>
        )}

        {isSabotage && (
          <Field label="Способ саботажа" tone="bad">
            <Dropdown
              options={sabotageModes}
              selected={sabotageMode}
              onSelected={setSabotageMode}
            />
          </Field>
        )}

        {usesLocation && (
          <div className="StyleGuide__formGrid StyleGuide__formGrid--location">
            <Field label="Зона">
              <input className="StyleGuide__textInput" value={targetArea} onChange={(event) => setTargetArea(event.currentTarget.value)} />
            </Field>
            <Field label="X">
              <input className="StyleGuide__textInput" type="number" value={targetX} onChange={numInputHandler(setTargetX)} />
            </Field>
            <Field label="Y">
              <input className="StyleGuide__textInput" type="number" value={targetY} onChange={numInputHandler(setTargetY)} />
            </Field>
            <Field label="Z">
              <input className="StyleGuide__textInput" type="number" value={targetZ} onChange={numInputHandler(setTargetZ)} />
            </Field>
            <Field label="Радиус">
              <input className="StyleGuide__textInput" type="number" value={targetRadius} onChange={numInputHandler(setTargetRadius)} />
            </Field>
          </div>
        )}
      </div>

      <div className="StyleGuide__formGrid StyleGuide__formGrid--toggles">
        <Toggle label={`Легальный: ${boolLabel(legal)}`} checked={legal} onClick={() => setLegal(!legal)} />
        <Toggle label={`Публичный: ${boolLabel(isPublic)}`} checked={isPublic} onClick={() => setPublic(!isPublic)} />
        <Toggle label={`Ручное подтверждение: ${boolLabel(creatorConfirm)}`} checked={creatorConfirm} onClick={() => setCreatorConfirm(!creatorConfirm)} />
        {isGuard && (
          <Toggle label={`Частичная охрана: ${boolLabel(partialGuardPayment)}`} checked={partialGuardPayment} onClick={() => setPartialGuardPayment(!partialGuardPayment)} />
        )}
      </div>

      <button
        type="button"
        className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
        disabled={creationDisabled}
        onClick={() =>
          act('create', {
            title,
            description,
            target,
            assigned_contractor: assignedContractor,
            contract_type: contractType,
            payment,
            deposit,
            penalty,
            duration_minutes: duration,
            required_amount: usesAmount ? requiredAmount : 1,
            required_percent: usesThreshold ? requiredPercent : 75,
            target_area: targetArea,
            target_type: targetType,
            target_x: targetX,
            target_y: targetY,
            target_z: targetZ,
            target_radius: targetRadius,
            minimum_quality: usesQuality ? minimumQuality : 0,
            minimum_rarity: usesQuality ? minimumRarity : 0,
            delivery_target_kind: isDelivery ? deliveryTargetKind : 'item',
            destination_kind: isDelivery ? destinationKind : 'creator',
            destination: cleanDestination,
            repair_mode: isRepair ? repairMode : 'integrity',
            guard_kind: isGuard ? guardKind : 'target',
            sabotage_mode: isSabotage ? sabotageMode : 'damage',
            elimination_mode: contractType === 'elimination' ? eliminationMode : 'critical',
            legal: legal ? 1 : 0,
            public_contract: isPublic ? 1 : 0,
            creator_confirm_required: creatorConfirm ? 1 : 0,
            reserve_held: deliveryNeedsReservedItem ? 1 : 0,
            reserved_item_ref: deliveryNeedsReservedItem ? effectiveReservedItemRef : '',
            partial_guard_payment: isGuard && partialGuardPayment ? 1 : 0,
            funding_business_id: fundingBusinessId,
          })
        }
      >
        <Icon name="file-signature" />
        <span>Зарезервировать оплату и опубликовать</span>
      </button>
    </div>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
