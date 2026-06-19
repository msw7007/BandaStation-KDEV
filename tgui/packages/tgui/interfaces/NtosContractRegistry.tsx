// CYBERPUNK BUILD - rebuild and delete before release
import { useState, type ReactNode } from 'react';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { NtosWindow } from '../layouts';
import { useBackend } from '../backend';

type RegistryContract = {
  id: number;
  title: string;
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
  public: BooleanLike;
  deadline: string;
  history?: string[];
};

type Data = {
  contracts: RegistryContract[];
  activeCount: number;
  completedCount: number;
  failedCount: number;
  taxRate: number;
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

function contractTypeLabel(type: string) {
  return contractTypes.find(([value]) => value === type)?.[1] || type || '-';
}

function boolLabel(value: BooleanLike) {
  return value ? 'да' : 'нет';
}

function moneyText(value: number) {
  return `${formatMoney(value || 0)} кр`;
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

export const NtosContractRegistry = () => {
  const { data } = useBackend<Data>();
  const {
    contracts = [],
    activeCount = 0,
    completedCount = 0,
    failedCount = 0,
    taxRate = 0,
  } = data;
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const selectedContract =
    contracts.find((contract) => contract.id === selectedId) || contracts[0];

  return (
    <NtosWindow width={860} height={660}>
      <NtosWindow.Content scrollable className="CyberpunkPanel StyleGuide">
        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Юридический реестр контрактов</div>
          <div className="StyleGuide__blockMetrics StyleGuide__blockMetrics--five">
            <Metric label="Записей" value={contracts.length} />
            <Metric label="Активно" value={activeCount} tone="good" />
            <Metric label="Выполнено" value={completedCount} tone="good" />
            <Metric label="Провалено" value={failedCount} tone="bad" />
            <Metric label="Налог" value={`${taxRate}%`} />
          </div>
        </div>

        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Записи</div>
          {!contracts.length ? (
            <div className="StyleGuide__placeholder">
              В реестре нет легальных контрактов.
            </div>
          ) : (
            <div className="StyleGuide__masterDetail StyleGuide__masterDetail--registry">
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
                        <small className={toneClass('good')}>
                          {moneyText(contract.payment)}
                        </small>
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
              </div>

              <div className="StyleGuide__detailPane">
                {!!selectedContract && (
                  <RegistryDetails contract={selectedContract} />
                )}
              </div>
            </div>
          )}
        </div>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const Metric = (props: {
  label: string;
  value: ReactNode;
  tone?: 'base' | 'good' | 'bad';
}) => (
  <span>
    <small>{props.label}</small>
    <b className={toneClass(props.tone)}>{props.value}</b>
  </span>
);

const RegistryDetails = (props: { contract: RegistryContract }) => {
  const { contract } = props;
  return (
    <article className="StyleGuide__dataCard">
      <div className="StyleGuide__dataCardContent">
        <div className="StyleGuide__dataCardTitle">
          <b>
            Реестр #{contract.id}: {contract.title}
          </b>
          <small className={toneClass(statusTone(contract.status))}>
            {contract.status}
          </small>
        </div>

        <div className="StyleGuide__contractMatrix">
          <RegistryCell label="Тип" value={contractTypeLabel(contract.type)} />
          <RegistryCell label="Цель" value={contract.target || '-'} />
          <RegistryCell label="Оплата" value={moneyText(contract.payment)} tone="good" />
          <RegistryCell
            label="Срок"
            value={contract.deadline || '-'}
            tone={contract.deadline === 'expired' ? 'bad' : 'base'}
          />
          <RegistryCell label="Создатель" value={contract.creator || '-'} />
          <RegistryCell
            label="Исполнитель"
            value={contract.contractor || contract.assignedContractor || 'открыто'}
          />
          <RegistryCell label="Публичный" value={boolLabel(contract.public)} />
          <RegistryCell label="Депозит" value={moneyText(contract.deposit)} />
          <RegistryCell
            label="Штраф"
            value={moneyText(contract.penalty)}
            tone={contract.penalty > 0 ? 'bad' : 'base'}
          />
          <RegistryCell
            label="Налог"
            value={moneyText(contract.taxPaid)}
            tone={contract.taxPaid > 0 ? 'bad' : 'base'}
          />
        </div>

        {!!contract.history?.length && (
          <details>
            <summary>История</summary>
            {contract.history.map((entry, index) => (
              <div key={index} className="StyleGuide__trapezoidNote">
                {entry}
              </div>
            ))}
          </details>
        )}
      </div>
    </article>
  );
};

const RegistryCell = (props: {
  label: string;
  value: ReactNode;
  tone?: 'base' | 'good' | 'bad';
}) => (
  <div className="StyleGuide__contractCell">
    <span>{props.label}</span>
    <b className={toneClass(props.tone)}>{props.value}</b>
  </div>
);
// CYBERPUNK BUILD - rebuild and delete before release
