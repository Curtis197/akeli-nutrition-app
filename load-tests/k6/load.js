// Phase 2 — Deep-dive load test (sustained VUs, thresholds enforced)
// Run via: k6 cloud load-tests/k6/load.js

import { generateMealPlan } from './scenarios/generate-meal-plan.js';
import { batchGenerateMealPlans } from './scenarios/batch-generate-meal-plans.js';
import { aiAssistantChat, analyzeMealPhoto } from './scenarios/ai-features.js';
import { toggleRecipeLike, toggleRecipeSave, postgrestRecipeFeed } from './scenarios/social-feed.js';
import { notifyGroupMessage } from './scenarios/community.js';

export const options = {
  scenarios: {
    generate_meal_plan: {
      executor: 'constant-vus',
      vus: 500,
      duration: '10m',
      exec: 'execGenerateMealPlan',
    },
    batch_generate_meal_plans: {
      executor: 'constant-vus',
      vus: 20,           // low VU — each call runs a large batch internally
      duration: '10m',
      exec: 'execBatchGenerateMealPlans',
    },
    // AI scenarios run as separate scenarios with independent VU counts
    // so metrics and thresholds are isolated per function
    ai_assistant_chat: {
      executor: 'constant-vus',
      vus: 100,
      duration: '10m',
      exec: 'execAiAssistantChat',
    },
    analyze_meal_photo: {
      executor: 'constant-vus',
      vus: 50,           // lower VU — each call invokes vision AI, very expensive
      duration: '10m',
      exec: 'execAnalyzeMealPhoto',
    },
    social_feed: {
      executor: 'constant-vus',
      vus: 1000,
      duration: '10m',
      exec: 'execSocialFeed',
    },
    community: {
      executor: 'constant-vus',
      vus: 200,
      duration: '10m',
      exec: 'execCommunity',
    },
  },
  thresholds: {
    'http_req_duration{scenario:generate_meal_plan}':      ['p(95)<10000'],
    'http_req_failed{scenario:generate_meal_plan}':        ['rate<0.01'],
    'http_req_duration{scenario:batch_generate_meal_plans}': ['p(95)<60000'],
    'http_req_failed{scenario:batch_generate_meal_plans}': ['rate<0.02'],
    'http_req_duration{scenario:ai_assistant_chat}':       ['p(95)<20000'],
    'http_req_failed{scenario:ai_assistant_chat}':         ['rate<0.02'],
    'http_req_duration{scenario:analyze_meal_photo}':      ['p(95)<25000'],
    'http_req_failed{scenario:analyze_meal_photo}':        ['rate<0.02'],
    'http_req_duration{scenario:toggle_recipe_like}':      ['p(95)<300'],
    'http_req_failed{scenario:toggle_recipe_like}':        ['rate<0.005'],
    'http_req_duration{scenario:toggle_recipe_save}':      ['p(95)<300'],
    'http_req_failed{scenario:toggle_recipe_save}':        ['rate<0.005'],
    'http_req_duration{scenario:postgrest_recipe_feed}':   ['p(95)<500'],
    'http_req_failed{scenario:postgrest_recipe_feed}':     ['rate<0.005'],
    'http_req_duration{scenario:notify_group_message}':    ['p(95)<1000'],
    'http_req_failed{scenario:notify_group_message}':      ['rate<0.01'],
  },
};

export function execGenerateMealPlan()      { generateMealPlan(); }
export function execBatchGenerateMealPlans() { batchGenerateMealPlans(); }
export function execAiAssistantChat()       { aiAssistantChat(); }
export function execAnalyzeMealPhoto()      { analyzeMealPhoto(); }
export function execSocialFeed()            { toggleRecipeLike(); toggleRecipeSave(); postgrestRecipeFeed(); }
export function execCommunity()             { notifyGroupMessage(); }
