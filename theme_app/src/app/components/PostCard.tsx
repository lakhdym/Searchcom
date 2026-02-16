import React, { useState } from 'react';
import { Heart, MessageCircle, MoreVertical, MapPin, Calendar, MessageSquare, Phone } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { motion, AnimatePresence } from 'motion/react';
import { toast } from 'sonner';
import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import { CommentsModal } from './CommentsModal';

export interface Post {
  id: string;
  type: 'lost' | 'found';
  title: string;
  description: string;
  location: string;
  date: string;
  imageUrl: string;
  likes: number;
  comments: number;
  phone?: string;
}

interface PostCardProps {
  post: Post;
}

export const PostCard: React.FC<PostCardProps> = ({ post }) => {
  const isLost = post.type === 'lost';
  const [isLiked, setIsLiked] = useState(false);
  const [likesCount, setLikesCount] = useState(post.likes);
  const [showComments, setShowComments] = useState(false);
  
  const handleLike = () => {
    setIsLiked(!isLiked);
    setLikesCount(prev => isLiked ? prev - 1 : prev + 1);
  };

  const handleWhatsApp = () => {
    if (post.phone) {
      window.open(`https://wa.me/${post.phone.replace(/\s+/g, '')}`, '_blank');
    } else {
      // Fallback if no phone (shouldn't happen with real data)
      window.open('https://wa.me/', '_blank');
    }
  };

  const handleChat = () => {
    // In a real app, this would open a chat window or navigate to /chat/:id
    toast.success(`Ouverture de la discussion pour : ${post.title}`);
    
    // You would typically emit an event or use a router here
    const event = new CustomEvent('open-chat', { detail: { post } });
    window.dispatchEvent(event);
  };
  
  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow"
    >
      {/* Header Image */}
      <div className="relative aspect-[4/3] w-full bg-gray-100">
        <ImageWithFallback 
          src={post.imageUrl} 
          alt={post.title}
          className="w-full h-full object-cover"
        />
        <div className={`absolute top-4 left-4 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider shadow-sm text-white ${isLost ? 'bg-red-500' : 'bg-green-500'}`}>
          {isLost ? 'Perdu' : 'Trouvé'}
        </div>
        <button className="absolute top-4 right-4 p-2 bg-white/80 backdrop-blur-sm rounded-full text-gray-700 hover:bg-white transition-colors">
          <MoreVertical size={16} />
        </button>
      </div>

      {/* Content */}
      <div className="p-5">
        <div className="flex justify-between items-start mb-2">
          <h3 className="text-lg font-bold text-gray-900 line-clamp-1">{post.title}</h3>
          <div className="flex items-center text-xs text-gray-500 gap-1 bg-gray-50 px-2 py-1 rounded-md">
            <Calendar size={12} />
            {post.date}
          </div>
        </div>
        
        <p className="text-gray-600 text-sm line-clamp-2 mb-4">
          {post.description}
        </p>

        <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
          <MapPin size={16} className="text-violet-500" />
          {post.location}
        </div>

        {/* Actions */}
        <div className="flex items-center justify-between border-t border-gray-100 pt-4">
          <div className="flex gap-4">
            <button 
              onClick={handleLike}
              className={`flex items-center gap-1.5 transition-colors group ${isLiked ? 'text-red-500' : 'text-gray-500 hover:text-red-500'}`}
            >
              <Heart 
                size={20} 
                className={`transition-transform ${isLiked ? 'fill-current scale-110' : 'group-hover:scale-110'}`} 
              />
              <span className="text-sm font-medium">{likesCount}</span>
            </button>
            <button 
              onClick={() => setShowComments(true)}
              className="flex items-center gap-1.5 text-gray-500 hover:text-violet-500 transition-colors"
            >
              <MessageCircle size={20} />
              <span className="text-sm font-medium">{post.comments}</span>
            </button>
          </div>

          <div className="flex gap-2">
            <DropdownMenu.Root>
              <DropdownMenu.Trigger asChild>
                <button 
                  className="flex items-center justify-center w-10 h-10 bg-violet-600 hover:bg-violet-700 text-white rounded-full shadow-md shadow-violet-200 transition-all outline-none focus:ring-2 focus:ring-violet-200"
                  title="Contacter"
                >
                  <MessageSquare size={18} />
                </button>
              </DropdownMenu.Trigger>

              <DropdownMenu.Portal>
                <DropdownMenu.Content 
                  className="min-w-[180px] bg-white rounded-xl shadow-xl border border-gray-100 p-1.5 animate-in fade-in zoom-in-95 duration-200 z-50"
                  sideOffset={5}
                  align="end"
                >
                  <DropdownMenu.Item 
                    onClick={handleWhatsApp}
                    className="flex items-center gap-3 px-3 py-2.5 text-sm text-gray-700 hover:bg-green-50 hover:text-green-700 rounded-lg cursor-pointer outline-none transition-colors"
                  >
                    <div className="w-8 h-8 rounded-full bg-green-100 text-green-600 flex items-center justify-center">
                       <Phone size={16} />
                    </div>
                    <span className="font-medium">WhatsApp</span>
                  </DropdownMenu.Item>

                  <DropdownMenu.Item 
                    onClick={handleChat}
                    className="flex items-center gap-3 px-3 py-2.5 text-sm text-gray-700 hover:bg-violet-50 hover:text-violet-700 rounded-lg cursor-pointer outline-none transition-colors"
                  >
                    <div className="w-8 h-8 rounded-full bg-violet-100 text-violet-600 flex items-center justify-center">
                      <MessageSquare size={16} />
                    </div>
                    <span className="font-medium">Chat interne</span>
                  </DropdownMenu.Item>
                  
                  <DropdownMenu.Arrow className="fill-white" />
                </DropdownMenu.Content>
              </DropdownMenu.Portal>
            </DropdownMenu.Root>
          </div>
        </div>
      </div>

      <AnimatePresence>
        {showComments && (
          <CommentsModal 
            isOpen={showComments} 
            onClose={() => setShowComments(false)}
            postId={post.id}
            initialCount={post.comments}
          />
        )}
      </AnimatePresence>
    </motion.div>
  );
};

