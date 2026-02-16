import React, { useState } from 'react';
import { Search, MapPin, Calendar, Filter, SearchX, CheckCircle2 } from 'lucide-react';
import { Post, PostCard } from './PostCard';
import { motion } from 'motion/react';

interface HomeProps {
  onNavigateForm: (type: 'lost' | 'found') => void;
}

const MOCK_POSTS: Post[] = [
  {
    id: '1',
    type: 'lost',
    title: 'Portefeuille en cuir noir',
    description: 'Perdu près de la gare Casa Voyageurs. Contient des cartes bancaires et CIN.',
    location: 'Casablanca, Gare',
    date: 'Aujourd\'hui, 09:30',
    imageUrl: 'https://images.unsplash.com/photo-1614260937560-c749cc17da94?auto=format&fit=crop&w=800&q=80',
    likes: 12,
    comments: 3,
    phone: '212612345678'
  },
  {
    id: '2',
    type: 'found',
    title: 'Clés de voiture BMW',
    description: 'Trouvées sur un banc dans le parc. Porte-clés rouge.',
    location: 'Rabat, Agdal',
    date: 'Hier, 18:45',
    imageUrl: 'https://images.unsplash.com/photo-1613354208673-837fe9632c33?auto=format&fit=crop&w=800&q=80',
    likes: 45,
    comments: 8,
    phone: '212698765432'
  },
  {
    id: '3',
    type: 'lost',
    title: 'Chien Golden Retriever',
    description: 'Répond au nom de Max. Collier bleu. Très gentil.',
    location: 'Marrakech, Gueliz',
    date: '2 Fév, 14:00',
    imageUrl: 'https://images.unsplash.com/photo-1596739289283-de6f6847fe28?auto=format&fit=crop&w=800&q=80',
    likes: 120,
    comments: 24,
    phone: '212611223344'
  },
  {
    id: '4',
    type: 'found',
    title: 'iPhone 13 Pro',
    description: 'Écran verrouillé, coque transparente. Trouvé au café Starbucks.',
    location: 'Tanger, Centre',
    date: '30 Jan, 11:20',
    imageUrl: 'https://images.unsplash.com/photo-1565686229779-3d416272baf3?auto=format&fit=crop&w=800&q=80',
    likes: 8,
    comments: 1,
    phone: '212655443322'
  }
];

export const Home: React.FC<HomeProps> = ({ onNavigateForm }) => {
  const [filter, setFilter] = useState<'all' | 'lost' | 'found'>('all');

  const filteredPosts = MOCK_POSTS.filter(post => {
    if (filter === 'all') return true;
    return post.type === filter;
  });

  return (
    <div className="space-y-8">
      {/* Hero / Action Section */}
      <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={() => onNavigateForm('lost')}
          className="relative overflow-hidden bg-gradient-to-br from-red-50 to-white p-8 rounded-3xl border border-red-100 shadow-sm group text-left hover:shadow-red-100/50 hover:shadow-lg transition-all"
        >
          <div className="absolute top-0 right-0 p-8 opacity-10 group-hover:opacity-20 transition-opacity">
            <SearchX size={120} className="text-red-500" />
          </div>
          <div className="relative z-10">
            <div className="w-12 h-12 bg-red-100 text-red-600 rounded-2xl flex items-center justify-center mb-4 text-2xl group-hover:scale-110 transition-transform">
              💔
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">J'ai perdu</h2>
            <p className="text-gray-600">
              Signalez un objet perdu pour augmenter vos chances de le retrouver.
            </p>
          </div>
        </motion.button>

        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={() => onNavigateForm('found')}
          className="relative overflow-hidden bg-gradient-to-br from-green-50 to-white p-8 rounded-3xl border border-green-100 shadow-sm group text-left hover:shadow-green-100/50 hover:shadow-lg transition-all"
        >
          <div className="absolute top-0 right-0 p-8 opacity-10 group-hover:opacity-20 transition-opacity">
            <CheckCircle2 size={120} className="text-green-500" />
          </div>
          <div className="relative z-10">
            <div className="w-12 h-12 bg-green-100 text-green-600 rounded-2xl flex items-center justify-center mb-4 text-2xl group-hover:scale-110 transition-transform">
              🤝
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">J'ai trouvé</h2>
            <p className="text-gray-600">
              Aidez quelqu'un à retrouver son bien en publiant une annonce.
            </p>
          </div>
        </motion.button>
      </section>

      {/* Search Bar */}
      <div className="bg-white p-2 rounded-2xl shadow-sm border border-gray-100 flex items-center gap-2">
        <div className="flex-1 flex items-center gap-3 px-4 py-2 bg-gray-50 rounded-xl">
          <Search size={20} className="text-gray-400" />
          <input 
            type="text" 
            placeholder="Rechercher (objet, lieu, mot-clé...)" 
            className="bg-transparent border-none outline-none w-full text-gray-900 placeholder-gray-400"
          />
        </div>
        <button className="p-3 text-gray-500 hover:bg-gray-50 rounded-xl transition-colors hidden sm:block">
          <MapPin size={20} />
        </button>
        <button className="p-3 text-gray-500 hover:bg-gray-50 rounded-xl transition-colors hidden sm:block">
          <Calendar size={20} />
        </button>
        <button className="p-3 bg-violet-600 text-white rounded-xl hover:bg-violet-700 transition-colors shadow-lg shadow-violet-200">
          <Filter size={20} />
        </button>
      </div>

      {/* Feed */}
      <section>
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <h2 className="text-xl font-bold text-gray-900">Publications récentes</h2>
          
          <div className="flex bg-gray-100 p-1 rounded-xl self-start sm:self-auto">
            <button 
              onClick={() => setFilter('all')}
              className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${filter === 'all' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-900'}`}
            >
              Tout
            </button>
            <button 
              onClick={() => setFilter('lost')}
              className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${filter === 'lost' ? 'bg-white text-red-600 shadow-sm' : 'text-gray-500 hover:text-red-600'}`}
            >
              Perdu
            </button>
            <button 
              onClick={() => setFilter('found')}
              className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${filter === 'found' ? 'bg-white text-green-600 shadow-sm' : 'text-gray-500 hover:text-green-600'}`}
            >
              Trouvé
            </button>
          </div>
        </div>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredPosts.map(post => (
            <PostCard key={post.id} post={post} />
          ))}
          {filteredPosts.length === 0 && (
            <div className="col-span-full py-12 text-center text-gray-500 bg-gray-50 rounded-2xl border border-dashed border-gray-200">
              Aucune publication trouvée pour ce filtre.
            </div>
          )}
        </div>
      </section>
    </div>
  );
};
