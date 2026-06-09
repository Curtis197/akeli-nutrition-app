import { generateMealPlan } from './scenarios/generate-meal-plan.js';
import { batchGenerateMealPlans } from './scenarios/batch-generate-meal-plans.js';
import { toggleRecipeLike, postgrestRecipeFeed } from './scenarios/social-feed.js';

export const options = {
  scenarios: {
    generate_meal_plan: {
      executor: 'ramping-vus',
      startVUs: 10,
      stages: [
        { duration: '5m',  target: 500  },
        { duration: '10m', target: 2000 },
        { duration: '10m', target: 5000 },
        { duration: '5m',  target: 0   },
      ],
      exec: 'execGenerateMealPlan',
    },
    batch_generate_meal_plans: {
      executor: 'ramping-vus',
      startVUs: 10,
      stages: [
        { duration: '5m',  target: 100  },
        { duration: '10m', target: 500 },
        { duration: '10m', target: 1000 },
        { duration: '5m',  target: 0   },
      ],
      exec: 'execBatchGenerateMealPlans',
    },
    social_feed: {
      executor: 'ramping-vus',
      startVUs: 100,
      stages: [
        { duration: '5m',  target: 1000  },
        { duration: '10m', target: 3000 },
        { duration: '10m', target: 5000 },
        { duration: '5m',  target: 0   },
      ],
      exec: 'execSocialFeed',
    }
  },
  // No thresholds — finding the ceiling, not passing/failing
};

export function execGenerateMealPlan() { generateMealPlan(); }
export function execBatchGenerateMealPlans() { batchGenerateMealPlans(); }
export function execSocialFeed() { toggleRecipeLike(); postgrestRecipeFeed(); }
