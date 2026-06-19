import { useState } from 'react';
import { Box, Icon, LabeledList } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  type CorporateInterfaceData,
} from './NtosCorporations';

type PcApp = {
  id: string;
  name: string;
  category: string;
  status: string;
  description: string;
  icon?: string;
  nativeProgram?: string;
};

type PcData = {
  userName: string;
  accountName?: string;
  accountBalance: number;
  hasNeuralInterface: BooleanLike;
  accessCard?: string;
  memoryKeys: number;
  canWriteCryptoKey?: BooleanLike;
  cryptoKeyTarget?: string;
  apps: PcApp[];
  activity: string[];
  corporationsInterface?: CorporateInterfaceData;
};

const categoryLabels: Record<string, string> = {
  Work: 'Работа',
  Corporate: 'Корпорации',
  Net: 'Сеть',
  City: 'Город',
  System: 'Система',
  Работа: 'Работа',
  Корпорации: 'Корпорации',
  Связь: 'Связь',
  Город: 'Город',
  Система: 'Система',
};

function appStatusLabel(status: string) {
  switch (status) {
    case 'ready':
      return 'готово';
    case 'program':
      return 'программа';
    case 'installed':
      return 'установлено';
    case 'running':
      return 'запущено';
    case 'not_installed':
      return 'не установлено';
    case 'needs_pc':
      return 'нужен ПК';
    case 'terminal':
      return 'терминал';
    case 'local':
      return 'локально';
    case 'planned':
      return 'план';
    case 'info':
      return 'витрина';
    default:
      return status || '-';
  }
}

function canOpenApp(status: string) {
  return ['ready', 'program', 'installed', 'running'].includes(status);
}

function CorporatePublicBoard(props: { data: CorporateInterfaceData }) {
  const corporations = props.data.corporations || [];

  return (
    <div className="StyleGuide__blockShell PcInterface__corporateBoard">
      <div className="StyleGuide__blockTitle">Корпоративная витрина</div>
      <div className="PcInterface__corporateGrid">
        {corporations.map((corp) => {
          const activeServices = (corp.services || []).filter(
            (service) => service.enabled,
          );
          return (
            <article key={corp.id} className="PcInterface__corporateCard">
              <div className="PcInterface__corporateTitle">
                <h2>{corp.name}</h2>
                <span>{corp.group}</span>
              </div>
              <div className="PcInterface__corporateLine">
                <b>Профиль</b>
                <span>{corp.direction}</span>
              </div>
              {!!corp.combatDoctrine && (
                <div className="PcInterface__corporateLine">
                  <b>Тактика</b>
                  <span>{corp.combatDoctrine}</span>
                </div>
              )}
              {!!corp.subsidiaries?.length && (
                <div className="PcInterface__corporateLine">
                  <b>Дочерние</b>
                  <span>{corp.subsidiaries.join(', ')}</span>
                </div>
              )}
              <div className="PcInterface__serviceStrip">
                <b>Активные услуги</b>
                {activeServices.length ? (
                  <div>
                    {activeServices.map((service) => (
                      <span key={service.id}>{service.label}</span>
                    ))}
                  </div>
                ) : (
                  <em>Активные услуги не объявлены</em>
                )}
              </div>
            </article>
          );
        })}
      </div>
      {!corporations.length && (
        <div className="StyleGuide__placeholder">
          Корпоративные записи недоступны.
        </div>
      )}
    </div>
  );
}

export const CyberpunkPcInterface = () => {
  const { act, data } = useBackend<PcData>();
  const apps = data.apps || [];
  const categories = Array.from(new Set(apps.map((app) => app.category)));
  const [category, setCategory] = useState(categories[0] || 'Work');
  const shownApps = apps.filter((app) => app.category === category);
  const [selectedId, setSelectedId] = useState('');
  const selected =
    apps.find((app) => app.id === selectedId && app.category === category) ||
    shownApps[0] ||
    apps[0];
  const isCorporatePromo =
    selected?.id === 'corporations' && data.corporationsInterface;

  return (
    <Window title="Городская рабочая станция" width={1080} height={760}>
      <Window.Content scrollable className="CyberpunkPanel StyleGuide PcInterface">
        <div className="StyleGuide__header PcInterface__header">
          <div>
            <div className="PcInterface__eyebrow">ГОРОДСКАЯ РАБОЧАЯ СТАНЦИЯ</div>
            <h1>{selected?.name || 'Приложения'}</h1>
          </div>
          <div className="PcInterface__account">
            <span>{data.userName || 'неизвестный пользователь'}</span>
            <b>{data.accountBalance || 0} кр</b>
            <em>{data.hasNeuralInterface ? 'нейролинк' : 'без нейролинка'}</em>
          </div>
        </div>

        <div className="PcInterface__identity">
          <div className="StyleGuide__blockShell">
            <div className="StyleGuide__blockTitle">Пользователь</div>
            <LabeledList>
              <LabeledList.Item label="Имя">{data.userName}</LabeledList.Item>
              <LabeledList.Item label="Счет">
                {data.accountName || 'нет'}
              </LabeledList.Item>
              <LabeledList.Item label="Баланс">
                {data.accountBalance || 0} кр
              </LabeledList.Item>
            </LabeledList>
          </div>
          <div className="StyleGuide__blockShell">
            <div className="StyleGuide__blockTitle">Доступ</div>
            <LabeledList>
              <LabeledList.Item label="Карта">
                {data.accessCard || 'нет'}
              </LabeledList.Item>
              <LabeledList.Item label="Нейролинк">
                {data.hasNeuralInterface ? 'обнаружен' : 'нет'}
              </LabeledList.Item>
              <LabeledList.Item label="Ключи памяти">
                {data.memoryKeys || 0}
              </LabeledList.Item>
            </LabeledList>
            <div className="StyleGuide__actionRow">
              <button
                type="button"
                className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                disabled={!data.canWriteCryptoKey}
                title={
                  data.cryptoKeyTarget
                    ? `Записать ключи на ${data.cryptoKeyTarget}`
                    : 'Нужна нейропамять и вставленная ID/диск'
                }
                onClick={() => act('write_crypto_key')}
              >
                <Icon name="key" />
                <span>Записать ключи</span>
              </button>
            </div>
          </div>
        </div>

        <div className="StyleGuide__topTabs PcInterface__tabs">
          {categories.map((entry) => (
            <button
              key={entry}
              type="button"
              className={category === entry ? 'active' : ''}
              onClick={() => setCategory(entry)}
            >
              {categoryLabels[entry] || entry}
            </button>
          ))}
        </div>

        <div className="PcInterface__layout">
          <aside className="StyleGuide__blockShell PcInterface__side">
            <div className="StyleGuide__blockTitle">Приложения</div>
            <div className="PcInterface__appList">
              {shownApps.map((app) => (
                <button
                  key={app.id}
                  type="button"
                  className={[
                    'PcInterface__appButton',
                    selected?.id === app.id && 'active',
                  ]
                    .filter(Boolean)
                    .join(' ')}
                  onClick={() => setSelectedId(app.id)}
                >
                  <span>
                    {!!app.icon && <Icon name={app.icon} />}
                    {app.name}
                  </span>
                  <small>{appStatusLabel(app.status)}</small>
                </button>
              ))}
              {!shownApps.length && (
                <div className="StyleGuide__placeholder">
                  В этой категории приложений нет.
                </div>
              )}
            </div>
            <div className="PcInterface__activity">
              <div className="StyleGuide__blockTitle">Активность</div>
              {(data.activity || []).map((entry, index) => (
                <Box key={index} className="PcInterface__activityLine">
                  {entry}
                </Box>
              ))}
            </div>
          </aside>

          <main className="PcInterface__main">
            {!selected ? (
              <div className="StyleGuide__blockShell">
                <div className="StyleGuide__placeholder">
                  Индекс приложений пуст.
                </div>
              </div>
            ) : isCorporatePromo ? (
              <CorporatePublicBoard data={data.corporationsInterface!} />
            ) : (
              <div className="StyleGuide__blockShell PcInterface__appCard">
                <div className="StyleGuide__blockTitle">{selected.name}</div>
                <h2>{selected.name}</h2>
                <p>{selected.description}</p>
                <div className="PcInterface__appMeta">
                  <span>{categoryLabels[selected.category] || selected.category}</span>
                  <b>{appStatusLabel(selected.status)}</b>
                </div>
                <button
                  type="button"
                  className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark PcInterface__openButton"
                  disabled={!canOpenApp(selected.status)}
                  onClick={() => act('open_app', { app: selected.id })}
                >
                  <Icon name="play" />
                  <span>Открыть</span>
                </button>
                {!canOpenApp(selected.status) && (
                  <div className="StyleGuide__placeholder">
                    {selected.status === 'not_installed'
                      ? 'Приложение есть в каталоге ПК, но не установлено. Установите его через NT Software Hub.'
                      : 'Для запуска нужен реальный ПК/ноутбук с установленной программой.'}
                  </div>
                )}
              </div>
            )}
          </main>
        </div>
      </Window.Content>
    </Window>
  );
};
