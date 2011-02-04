//
// EcoChallenge.
// Copyright (c) 2010-2011 Raureif GmbH. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


// Sub-class an UITableViewCell for the recommendation cell
// so we can adjust the highlighted state in a flexible way.

@interface ChallengeRecommendationCell: UITableViewCell {
    NSString *recommendation;
    UIImage *backgroundTexture;
    BOOL drawHighlighted;
}

@property (nonatomic, copy) NSString *recommendation;
@property (nonatomic, retain) UIImage *backgroundTexture;

@end
