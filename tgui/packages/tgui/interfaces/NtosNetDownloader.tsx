import { sortBy } from 'es-toolkit';
import { filter } from 'es-toolkit/compat';
import { useState } from 'react';
import { Icon } from 'tgui-core/components';
import { scale, toFixed } from 'tgui-core/math';
import type { BooleanLike } from 'tgui-core/react';
import { createSearch } from 'tgui-core/string';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type Data = {
  disk_size: number;
  disk_used: number;
  downloadcompletion: number;
  downloading: BooleanLike;
  downloadname: string;
  downloadsize: number;
  error: string;
  emagged: BooleanLike;
  categories: string[];
  programs: ProgramData[];
};

type ProgramData = {
  icon: string;
  filename: string;
  filedesc: string;
  fileinfo: string;
  category: string;
  installed: BooleanLike;
  compatible: BooleanLike;
  size: number;
  access: BooleanLike;
  verifiedsource: BooleanLike;
};

export const NtosNetDownloader = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    disk_size,
    disk_used,
    downloadcompletion,
    downloading,
    downloadname,
    downloadsize,
    error,
    emagged,
    categories = [],
    programs = [],
  } = data;
  const [selectedCategory, setSelectedCategory] = useState(categories[0]);
  const [searchItem, setSearchItem] = useState('');
  const search = createSearch<ProgramData>(
    searchItem,
    (program) => program.filedesc,
  );
  let items =
    searchItem.length > 0
      ? filter(programs, search)
      : filter(programs, (program) => program.category === selectedCategory);
  items = sortBy(items, [
    (program: ProgramData) => !program.compatible,
    (program: ProgramData) => program.filedesc,
  ]);
  if (!emagged) {
    items = filter(items, (program) => program.verifiedsource === 1);
  }

  const usedSpace = downloading ? disk_used + downloadcompletion : disk_used;
  const diskFreeSpace = downloading
    ? disk_size - Number(toFixed(usedSpace))
    : disk_size - disk_used;
  const diskPercent =
    disk_size > 0 ? Math.min(100, (usedSpace / disk_size) * 100) : 0;
  const downloadPercent = downloadsize
    ? toFixed(scale(downloadcompletion, 0, downloadsize) * 100)
    : 0;

  return (
    <NtosWindow width={600} height={600}>
      <NtosWindow.Content scrollable className="CyberpunkPanel StyleGuide">
        {!!error && (
          <div className="StyleGuide__blockShell">
            <div className="StyleGuide__blockTitle">Ошибка</div>
            <p>{error}</p>
            <button
              type="button"
              className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
              onClick={() => act('PRG_reseterror')}
            >
              <Icon name="times" />
              <span>Сбросить</span>
            </button>
          </div>
        )}

        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Жесткий диск</div>
          <div className="StyleGuide__thinProgress">
            <div className="StyleGuide__thinProgressMeta">
              <span>Свободно: {diskFreeSpace} GQ</span>
              <b>{disk_size} GQ</b>
            </div>
            <div className="StyleGuide__thinProgressTrack">
              <div style={{ width: `${diskPercent}%` }} />
            </div>
          </div>
          {!!downloading && (
            <div className="StyleGuide__trapezoidNote">
              Загрузка: {downloadname}.prg ({downloadPercent}%)
            </div>
          )}
          {!downloading && !!downloadname && (
            <div className="StyleGuide__trapezoidNote StyleGuide__trapezoidNote--meta">
              {downloadname}.prg загружен
            </div>
          )}
        </div>

        <div className="StyleGuide__fieldSample">
          <input
            autoFocus
            className="StyleGuide__textInput StyleGuide__textInput--cyan"
            placeholder="Найти программу..."
            value={searchItem}
            onChange={(event) => setSearchItem(event.currentTarget.value)}
          />
        </div>

        <div className="StyleGuide__textSwitch StyleGuide__textSwitch--redInactive">
          {categories.map((category) => (
            <button
              key={category}
              type="button"
              className={category === selectedCategory ? 'active' : ''}
              onClick={() => setSelectedCategory(category)}
            >
              <span>{category}</span>
            </button>
          ))}
        </div>

        <div className="StyleGuide__listStack">
          {items.map((program) => (
            <Program key={program.filename} program={program} />
          ))}
          {!items.length && (
            <div className="StyleGuide__placeholder">
              Программы не найдены.
            </div>
          )}
        </div>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const Program = (props: { program: ProgramData }) => {
  const { program } = props;
  const { act, data } = useBackend<Data>();
  const { disk_size, disk_used, downloading, downloadname, downloadcompletion } =
    data;
  const diskFree = disk_size - disk_used;
  const canDownload =
    !program.installed &&
    program.compatible &&
    program.access &&
    program.size < diskFree;
  const isDownloading = !!downloading && program.filename === downloadname;
  const progressPercent = program.size
    ? Math.min(100, (downloadcompletion / program.size) * 100)
    : 0;
  const stateLabel = program.installed
    ? 'Установлено'
    : !program.compatible
      ? 'Несовместимо'
      : !program.access
        ? 'Нет доступа'
        : 'Нет места';

  return (
    <article className="StyleGuide__dataCard">
      <div className="StyleGuide__dataCardContent">
        <div className="StyleGuide__dataCardTitle">
          <b>
            {!!program.icon && <Icon name={program.icon} />}
            {program.filedesc}
          </b>
          <small>{program.size} GQ</small>
        </div>
        <p>{program.fileinfo}</p>
        {!program.verifiedsource && (
          <div className="StyleGuide__trapezoidNote StyleGuide__trapezoidNote--meta">
            Непроверенный источник. Nanotrasen не рекомендует неофициальное ПО.
          </div>
        )}
      </div>
      <div className="StyleGuide__dataCardAction">
        {isDownloading ? (
          <div className="StyleGuide__thinProgress">
            <div className="StyleGuide__thinProgressMeta">
              <span>Загрузка</span>
              <b>{toFixed(progressPercent)}%</b>
            </div>
            <div className="StyleGuide__thinProgressTrack">
              <div style={{ width: `${progressPercent}%` }} />
            </div>
          </div>
        ) : canDownload ? (
          <button
            type="button"
            className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
            disabled={!!downloading}
            onClick={() =>
              act('PRG_downloadfile', {
                filename: program.filename,
              })
            }
          >
            <Icon name="download" />
            <span>Загрузить</span>
          </button>
        ) : (
          <button
            type="button"
            className={[
              'StyleGuide__cutButton',
              program.installed
                ? 'StyleGuide__cutButton--cyan-light'
                : 'StyleGuide__cutButton--red-dark',
            ].join(' ')}
            disabled
          >
            <Icon name={program.installed ? 'check' : 'times'} />
            <span>{stateLabel}</span>
          </button>
        )}
      </div>
    </article>
  );
};
