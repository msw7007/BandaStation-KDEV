import { Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import type { CorporateMinigameData } from './types';

export const PapersPlease = () => {
  const { act, data } = useBackend<CorporateMinigameData>();
  const paper = data.paper;

  return (
    <div className="StyleGuide__blockShell">
      <div className="StyleGuide__blockTitle">Trade review</div>
      <div className="StyleGuide__trapezoidNote">
        Approve good deals, reject unsafe or useless deals, adjust the price when demand is high but the client cannot pay.
      </div>
      {paper && (
        <>
          <div className="StyleGuide__definitionGrid">
            <span>Product</span>
            <b>{paper.product}</b>
            <span>Offer</span>
            <b>{paper.price} credits</b>
            <span>Client budget</span>
            <b>{paper.budget} credits</b>
            <span>Demand</span>
            <b>{paper.demand}%</b>
            <span>Psychic profile</span>
            <b>{paper.profile}</b>
          </div>
          <Stack mt={1}>
            <Stack.Item grow>
              <button
                type="button"
                className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                onClick={() => act('paper_decide', { decision: 'approve' })}
              >
                Approve
              </button>
            </Stack.Item>
            <Stack.Item grow>
              <button
                type="button"
                className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                onClick={() => act('paper_decide', { decision: 'adjust' })}
              >
                Adjust
              </button>
            </Stack.Item>
            <Stack.Item grow>
              <button
                type="button"
                className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
                onClick={() => act('paper_decide', { decision: 'reject' })}
              >
                Reject
              </button>
            </Stack.Item>
          </Stack>
        </>
      )}
    </div>
  );
};
