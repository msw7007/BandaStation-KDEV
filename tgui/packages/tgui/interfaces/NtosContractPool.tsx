// CYBERPUNK BUILD - rebuild and delete before release
import { Icon } from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type PoolContract = {
  id: number;
  title: string;
  description: string;
  type: string;
  target: string;
  status: string;
  creator: string;
  payment: number;
  deposit: number;
  penalty: number;
  legal: BooleanLike;
  pool: BooleanLike;
  corporation?: string;
  requiredAmount: number;
  deliveredAmount: number;
  requiredPercent: number;
  deadline: string;
  canAccept: BooleanLike;
  history?: string[];
};

type Data = {
  accountName?: string;
  accountBalance: number;
  contracts: PoolContract[];
};

function formatContractType(type: string) {
  const labels: Record<string, string> = {
    delivery: 'Доставка',
    repair: 'Ремонт',
    build: 'Стройка',
    guard: 'Охрана',
    mining: 'Добыча',
    sabotage: 'Саботаж',
    elimination: 'Устранение',
  };
  return labels[type] || type || '-';
}

export const NtosContractPool = () => {
  const { data } = useBackend<Data>();
  const { accountName, accountBalance = 0, contracts = [] } = data;

  return (
    <NtosWindow width={760} height={660}>
      <NtosWindow.Content scrollable className="CyberpunkPanel StyleGuide">
        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Корпоративный пул контрактов</div>
          <dl className="StyleGuide__definitionGrid">
            <dt>ID счет</dt>
            <dd>{accountName || 'ID счет не найден'}</dd>
            <dt>Баланс</dt>
            <dd>{formatMoney(accountBalance)} кр</dd>
            <dt>Доступно</dt>
            <dd>{contracts.length}</dd>
          </dl>
        </div>

        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Предложения</div>
          <div className="StyleGuide__listStack">
            {contracts.map((contract) => (
              <PoolContractCard key={contract.id} contract={contract} />
            ))}
            {!contracts.length && (
              <div className="StyleGuide__placeholder">
                Доступных контрактов пула нет.
              </div>
            )}
          </div>
        </div>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const PoolContractCard = (props: { contract: PoolContract }) => {
  const { act } = useBackend<Data>();
  const { contract } = props;
  return (
    <article className="StyleGuide__dataCard">
      <div className="StyleGuide__dataCardContent">
        <div className="StyleGuide__dataCardTitle">
          <b>
            #{contract.id} {contract.title}
          </b>
          <small>{formatMoney(contract.payment)} кр</small>
        </div>
        <dl className="StyleGuide__definitionGrid">
          <dt>Корпорация</dt>
          <dd>{contract.corporation || contract.creator}</dd>
          <dt>Тип</dt>
          <dd>{formatContractType(contract.type)}</dd>
          <dt>Цель</dt>
          <dd>{contract.target}</dd>
          <dt>Срок</dt>
          <dd>{contract.deadline}</dd>
          <dt>Условие</dt>
          <dd>
            {contract.deliveredAmount}/{contract.requiredAmount}, порог{' '}
            {contract.requiredPercent}%
          </dd>
          <dt>Депозит / штраф</dt>
          <dd>
            {formatMoney(contract.deposit)} / {formatMoney(contract.penalty)} кр
          </dd>
        </dl>
        {!!contract.description && <p>{contract.description}</p>}
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
      <div className="StyleGuide__dataCardAction">
        <button
          type="button"
          className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
          disabled={!contract.canAccept}
          onClick={() => act('accept', { id: contract.id })}
        >
          <Icon name="handshake" />
          <span>Взять</span>
        </button>
      </div>
    </article>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
