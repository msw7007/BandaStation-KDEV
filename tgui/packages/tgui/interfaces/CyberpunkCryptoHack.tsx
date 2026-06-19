// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import { Icon } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CryptoOption = {
  index: number;
  text: string;
  selected: BooleanLike;
  wrongHint: BooleanLike;
  result?: string;
};

type CryptoColumn = {
  index: number;
  selectedIndex: number;
  options: CryptoOption[];
};

type CryptoHackData = {
  targetName: string;
  keyName: string;
  owner: string;
  maskedKey: string;
  selectedCode: string;
  hackingSkill: number;
  intelligence: number;
  columns: CryptoColumn[];
  aligned: BooleanLike;
  revealTimer: number;
  revealDelay: number;
  revealedCount: number;
  lastErrorCount: number;
};

export const CyberpunkCryptoHack = () => {
  const { act, data } = useBackend<CryptoHackData>();
  const {
    targetName,
    keyName,
    owner,
    maskedKey,
    selectedCode,
    hackingSkill,
    intelligence,
    columns = [],
    aligned,
    revealTimer,
    revealDelay,
    revealedCount,
    lastErrorCount,
  } = data;
  const [code, setCode] = useState('');

  const getSegmentClass = (option: CryptoOption) =>
    [
      'StyleGuide__switch',
      'CryptoHack__segment',
      option.result === 'correct' && 'active',
      option.result === 'wrong' && 'CryptoHack__segment--wrong',
      !option.result && option.selected && 'active',
      !option.result && !option.selected && option.wrongHint && 'CryptoHack__segment--wrong',
    ]
      .filter(Boolean)
      .join(' ');

  return (
    <Window width={780} height={650}>
      <Window.Content scrollable className="CyberpunkPanel StyleGuide">
        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Взлом криптоключа</div>
          <div className="CryptoHack__header">
            <div className="StyleGuide__trapezoidNote">
              <b>{targetName}</b>
              <span>
                {keyName} / {owner}
              </span>
            </div>
            <div className="StyleGuide__blockMetrics">
              <Metric label="Взлом / INT" value={`${hackingSkill} / ${intelligence}`} />
              <Metric label="Открытие" value={`${revealTimer}s`} />
              <Metric label="Прогресс" value={`${revealedCount}/20 / ${revealDelay}s`} />
            </div>
          </div>
        </div>

        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Образ ключа</div>
          <div className="CryptoHack__keyGrid">
            <KeyLine label="Маска навыка" value={maskedKey} />
            <KeyLine label="Выбранный вывод" value={selectedCode} />
          </div>
        </div>

        <div className="StyleGuide__blockShell">
          <div className="CryptoHack__titleRow">
            <div className="StyleGuide__blockTitle">Решатель колонок</div>
            <button
              type="button"
              className={[
                'StyleGuide__cutButton',
                aligned
                  ? 'StyleGuide__cutButton--cyan-light'
                  : 'StyleGuide__cutButton--cyan-dark',
              ].join(' ')}
              onClick={() => act('attempt_alignment')}
            >
              <Icon name="key" />
              <span>Подтвердить ключ</span>
            </button>
          </div>

          {!!lastErrorCount && (
            <div className="StyleGuide__trapezoidNote StyleGuide__trapezoidNote--meta">
              Последняя проверка отклонила {lastErrorCount} сегм.
            </div>
          )}

          <div className="CryptoHack__columnGrid">
            {columns.map((column) => (
              <div key={column.index} className="StyleGuide__createPanel CryptoHack__column">
                <div className="StyleGuide__blockTitle">Колонка {column.index}</div>
                <div className="CryptoHack__segmentStack">
                  {column.options.map((option) => (
                    <button
                      key={option.index}
                      type="button"
                      className={getSegmentClass(option)}
                      onClick={() =>
                        act('select_segment', {
                          column: column.index,
                          option: option.index,
                        })
                      }
                    >
                      <span>{option.text}</span>
                    </button>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Ручной ввод</div>
          <div className="CryptoHack__manualRow">
            <input
              className="StyleGuide__textInput StyleGuide__textInput--cyan"
              value={code}
              placeholder="20-символьный криптоключ"
              onChange={(event) => setCode(event.currentTarget.value)}
            />
            <button
              type="button"
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
              onClick={() => act('submit_code', { code })}
            >
              <Icon name="bolt" />
              <span>Активировать</span>
            </button>
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};

const Metric = (props: { label: string; value: string }) => (
  <span>
    <small>{props.label}</small>
    <b>{props.value}</b>
  </span>
);

const KeyLine = (props: {
  label: string;
  value: string;
  tone?: 'base' | 'good' | 'bad';
}) => (
  <label className="StyleGuide__formField">
    <span>{props.label}</span>
    <code
      className={[
        'CryptoHack__keyLine',
        props.tone === 'good' && 'StyleGuide__textGood',
        props.tone === 'bad' && 'StyleGuide__textBad',
      ]
        .filter(Boolean)
        .join(' ')}
    >
      {props.value}
    </code>
  </label>
);
// CYBERPUNK BUILD - rebuild and delete before release
