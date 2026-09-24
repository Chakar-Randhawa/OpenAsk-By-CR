import { Category } from '../types';

export interface CategorySeedData {
  id: string;
  name: string;
  slug: string;
  description: string;
  icon: string;
}

export const INITIAL_50_CATEGORIES: CategorySeedData[] = [
  { id: 'cat-technology', name: 'Technology', slug: 'technology', description: 'Computing, gadgets, digital tools, and tech trends.', icon: 'Cpu' },
  { id: 'cat-ai', name: 'Artificial Intelligence', slug: 'artificial-intelligence', description: 'Machine learning, neural networks, LLMs, and intelligent automation.', icon: 'Bot' },
  { id: 'cat-programming', name: 'Programming', slug: 'programming', description: 'Code architecture, software engineering, algorithms, and languages.', icon: 'Code' },
  { id: 'cat-science', name: 'Science', slug: 'science', description: 'Physics, chemistry, biology, empirical research, and discoveries.', icon: 'FlaskConical' },
  { id: 'cat-mathematics', name: 'Mathematics', slug: 'mathematics', description: 'Pure & applied mathematics, statistics, calculus, and logic.', icon: 'Binary' },
  { id: 'cat-education', name: 'Education', slug: 'education', description: 'Academic learning, pedagogy, university studies, and knowledge sharing.', icon: 'GraduationCap' },
  { id: 'cat-careers', name: 'Careers', slug: 'careers', description: 'Career progression, skill building, mentorship, and professional growth.', icon: 'Briefcase' },
  { id: 'cat-jobs', name: 'Jobs', slug: 'jobs', description: 'Interviews, hiring, resume crafting, and workplace navigation.', icon: 'Building' },
  { id: 'cat-business', name: 'Business', slug: 'business', description: 'Corporate strategy, operations, management, and global commerce.', icon: 'TrendingUp' },
  { id: 'cat-finance', name: 'Finance', slug: 'finance', description: 'Personal finance, banking, budgeting, and fiscal literacy.', icon: 'CreditCard' },
  { id: 'cat-investing', name: 'Investing', slug: 'investing', description: 'Equities, real estate, portfolio management, and wealth preservation.', icon: 'DollarSign' },
  { id: 'cat-entrepreneurship', name: 'Entrepreneurship', slug: 'entrepreneurship', description: 'Startups, venture scaling, product-market fit, and founder insights.', icon: 'Rocket' },
  { id: 'cat-history', name: 'History', slug: 'history', description: 'World historical events, civilizations, archives, and historical analysis.', icon: 'Landmark' },
  { id: 'cat-geography', name: 'Geography', slug: 'geography', description: 'Cartography, geopolitics, terrain, and global demographics.', icon: 'Globe' },
  { id: 'cat-politics', name: 'Politics', slug: 'politics', description: 'Governance, public policy, civic discourse, and international relations.', icon: 'Scale' },
  { id: 'cat-law', name: 'Law', slug: 'law', description: 'Legal systems, jurisprudence, constitutional law, and regulations.', icon: 'Shield' },
  { id: 'cat-psychology', name: 'Psychology', slug: 'psychology', description: 'Cognitive science, human behavior, emotional health, and perception.', icon: 'Brain' },
  { id: 'cat-philosophy', name: 'Philosophy', slug: 'philosophy', description: 'Ethics, epistemology, metaphysics, logic, and existential thought.', icon: 'BookOpen' },
  { id: 'cat-relationships', name: 'Relationships', slug: 'relationships', description: 'Interpersonal connections, family dynamics, friendships, and empathy.', icon: 'Heart' },
  { id: 'cat-parenting', name: 'Parenting', slug: 'parenting', description: 'Child development, family upbringing, education, and parental guidance.', icon: 'Users' },
  { id: 'cat-health', name: 'Health', slug: 'health', description: 'Medicine, wellness, preventive care, and physical health sciences.', icon: 'Activity' },
  { id: 'cat-fitness', name: 'Fitness', slug: 'fitness', description: 'Strength conditioning, endurance, athletic training, and mobility.', icon: 'Dumbbell' },
  { id: 'cat-nutrition', name: 'Nutrition', slug: 'nutrition', description: 'Dietary science, micronutrients, balanced eating, and metabolic health.', icon: 'Apple' },
  { id: 'cat-travel', name: 'Travel', slug: 'travel', description: 'Global destinations, cultures, travel itineraries, and transit tips.', icon: 'Compass' },
  { id: 'cat-food', name: 'Food', slug: 'food', description: 'Culinary traditions, ingredients, gastronomy, and international cuisines.', icon: 'Utensils' },
  { id: 'cat-cooking', name: 'Cooking', slug: 'cooking', description: 'Recipes, culinary techniques, kitchen craft, and baking.', icon: 'ChefHat' },
  { id: 'cat-movies', name: 'Movies', slug: 'movies', description: 'Cinema, filmmaking, screenwriting, directors, and critical reviews.', icon: 'Film' },
  { id: 'cat-television', name: 'Television', slug: 'television', description: 'Series, television production, episodic storytelling, and streaming.', icon: 'Tv' },
  { id: 'cat-music', name: 'Music', slug: 'music', description: 'Music theory, composition, audio engineering, genres, and artists.', icon: 'Music' },
  { id: 'cat-books', name: 'Books', slug: 'books', description: 'Literature, novels, non-fiction analysis, authors, and reading culture.', icon: 'Book' },
  { id: 'cat-gaming', name: 'Gaming', slug: 'gaming', description: 'Game design, video games, esports, mechanics, and interactive media.', icon: 'Gamepad2' },
  { id: 'cat-sports', name: 'Sports', slug: 'sports', description: 'Athletic competitions, team tactics, leagues, and sporting achievements.', icon: 'Trophy' },
  { id: 'cat-cars', name: 'Cars', slug: 'cars', description: 'Automotive engineering, electric vehicles, mechanics, and car culture.', icon: 'Car' },
  { id: 'cat-motorcycles', name: 'Motorcycles', slug: 'motorcycles', description: 'Two-wheel mechanics, touring, safety, and motorcycle riding.', icon: 'Bike' },
  { id: 'cat-photography', name: 'Photography', slug: 'photography', description: 'Composition, lighting, optics, camera gear, and visual capture.', icon: 'Camera' },
  { id: 'cat-art', name: 'Art', slug: 'art', description: 'Fine arts, sculpture, painting, creative expression, and art history.', icon: 'Palette' },
  { id: 'cat-design', name: 'Design', slug: 'design', description: 'UI/UX, graphic design, industrial design, and typography.', icon: 'Layout' },
  { id: 'cat-fashion', name: 'Fashion', slug: 'fashion', description: 'Textiles, apparel design, tailoring, styles, and garment crafts.', icon: 'Shirt' },
  { id: 'cat-beauty', name: 'Beauty', slug: 'beauty', description: 'Skincare, cosmetic science, grooming, and personal care routines.', icon: 'Sparkles' },
  { id: 'cat-animals', name: 'Animals', slug: 'animals', description: 'Zoology, wildlife conservation, animal behavior, and ecosystems.', icon: 'Footprints' },
  { id: 'cat-pets', name: 'Pets', slug: 'pets', description: 'Companion animal welfare, dog/cat care, training, and veterinary health.', icon: 'Dog' },
  { id: 'cat-nature', name: 'Nature', slug: 'nature', description: 'Ecology, forests, botany, conservation, and natural environments.', icon: 'Trees' },
  { id: 'cat-space', name: 'Space', slug: 'space', description: 'Astronomy, cosmology, space exploration, astrophysics, and planets.', icon: 'Telescope' },
  { id: 'cat-languages', name: 'Languages', slug: 'languages', description: 'Linguistics, language acquisition, polyglot tips, and grammar.', icon: 'Languages' },
  { id: 'cat-culture', name: 'Culture', slug: 'culture', description: 'Anthropology, traditions, global customs, and heritage.', icon: 'Smile' },
  { id: 'cat-lifestyle', name: 'Lifestyle', slug: 'lifestyle', description: 'Habit building, mindfulness, daily routines, and work-life balance.', icon: 'Sun' },
  { id: 'cat-diy', name: 'DIY', slug: 'diy', description: 'Woodworking, metalworking, electronics, repairs, and maker projects.', icon: 'Wrench' },
  { id: 'cat-home', name: 'Home', slug: 'home', description: 'Interior architecture, gardening, home maintenance, and living spaces.', icon: 'Home' },
  { id: 'cat-shopping', name: 'Shopping', slug: 'shopping', description: 'Consumer analysis, product comparisons, quality evaluation, and reviews.', icon: 'ShoppingBag' },
  { id: 'cat-general', name: 'General', slug: 'general', description: 'Open discussions, multifaceted inquiries, and broad topics.', icon: 'HelpCircle' }
];
